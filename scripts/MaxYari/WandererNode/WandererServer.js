const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const { Firestore } = require('@google-cloud/firestore');
const { v4: uuidv4 } = require('uuid');

process.title = "Server: The Wanderer";

// Initialize Firestore
let firestore;

if (process.env.FIRESTORE_EMULATOR_HOST) {
    firestore = new Firestore({
        projectId: process.env.GCLOUD_PROJECT,
    });
    firestore.settings({
        host: process.env.FIRESTORE_EMULATOR_HOST,
        ssl: false,
    });
} else {
    firestore = new Firestore({
        projectId: process.env.GCLOUD_PROJECT,
        keyFilename: 'path/to/your/serviceAccountKey.json',
    });
}

const app = express();
const server = http.createServer(app);
const io = socketIo(server);

app.use(express.json());

const wanderersCollection = firestore.collection('wanderers');

const clientCellMap = new Map(); // Map to keep track of client cell subscriptions

// Function to remove expired wanderers while keeping at least 3 freshest for the relevant cell
async function removeExpiredWanderers(cellId) {
    const minAmount = 3;
    const now = Date.now();
    const oneDayAgo = now - (24 * 60 * 60 * 1000);

    const snapshot = await wanderersCollection.where('c', '==', cellId).get();
    const wanderers = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

    // Sort wanderers by ts in descending order (freshest first)
    const sortedWanderers = wanderers.sort((a, b) => b.ts - a.ts);
    if (sortedWanderers.length <= minAmount) return;

    // Remove the freshest minAmount wanderers from the list
    const expiredWanderers = sortedWanderers.slice(minAmount).filter(wanderer => wanderer.ts < oneDayAgo);
    if (expiredWanderers.length === 0) return;

    console.log(`Removing ${expiredWanderers.length} expired wanderers for cell: ${cellId}. ${sortedWanderers.length - expiredWanderers.length} wanderers remaining.`);
    for (const wanderer of expiredWanderers) {
        await wanderersCollection.doc(wanderer.id).delete();
    }
}

// Socket connection handling
io.on('connection', (socket) => {
    console.log('New client connected');

    socket.on('subscribeToCell', async (cellId) => {
        const previousCellId = clientCellMap.get(socket.id);
        if (previousCellId) {
            socket.leave(previousCellId);
            console.log(`Client unsubscribed from cell: ${previousCellId}`);
        }

        socket.join(cellId);
        clientCellMap.set(socket.id, cellId);
        console.log(`Client subscribed to cell: ${cellId}`);

        // Fetch wanderers data and send it back via socket
        console.log(`Fetching wanderers data for cell: ${cellId}`);
        await removeExpiredWanderers(cellId);
        const snapshot = await wanderersCollection.where('c', '==', cellId).get();
        const wanderers = snapshot.docs.map(doc => doc.data());
        socket.emit('wanderersData', wanderers);
    });

    socket.on('updateWanderer', async (wandererData) => {
        wandererData.ts = Date.now();
        await wanderersCollection.doc(wandererData.id).set(wandererData, { merge: true });
        const updatedWanderer = (await wanderersCollection.doc(wandererData.id).get()).data();
        socket.to(updatedWanderer.c).emit('wandererUpdated', updatedWanderer);
    });

    socket.on('disconnect', () => {
        const cellId = clientCellMap.get(socket.id);
        if (cellId) {
            socket.leave(cellId);
            clientCellMap.delete(socket.id);
            console.log(`Client unsubscribed from cell: ${cellId}`);
        }
        console.log('Client disconnected');
    });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});
