const fs = require('fs');
const yaml = require('js-yaml');
const { v4: uuidv4 } = require('uuid');
const axios = require('axios');
const io = require('socket.io-client');
const { spawn } = require('child_process');

process.title = "Client: The Wanderer";

const serverUrl = 'http://localhost:3000';

const openMwPath = "C:/Games/OpenMW 0.49.0/openmw.exe";
const wanderersFilePath = '../WandererIPC/Wanderers.yaml';
const writePeriod = 100;
const socket = io(serverUrl);

let previousWandererData = {};
let wanderers = [];

// File utility
function writeYamlToFile(path, data) {
    // Remove timestamps since OpenMW lua cant parse them for whatever reason
    data.forEach(e => delete e.ts);
    const yamlContent = yaml.dump(data);
    fs.writeFileSync(path, yamlContent, 'utf8');
    console.log(`Written to file: ${path}`);
}



// Start the separate process and capture its stdout
console.log('Starting OpenMW.');
const exeProcess = spawn(openMwPath);


exeProcess.stdout.on('data', (data) => {
    const line = data.toString().trim();
    if (line.includes('[WnData]')) {
        const jsonData = line.split('[WnData]')[1].trim();
        try {
            onNewMyWandererData(JSON.parse(jsonData));
        } catch (e) {
            console.error('Error parsing JSON data:', e);
            console.error("Original received data was:", data);
        }
    } else {
        console.log(line);
    }
});

function onNewMyWandererData(data) {
    if (data.id && JSON.stringify(data) !== JSON.stringify(previousWandererData)) {
        if (data.c != previousWandererData.c || data.id != previousWandererData.id) {
            // Either cell got changed - or new character was loaded
            socket.emit('subscribeToCell', data.c);
        }
        previousWandererData = data;
        socket.emit('updateWanderer', data);
    }
}

exeProcess.stderr.on('data', (data) => {
    // console.error(`stderr: ${data}`);
});

exeProcess.on('close', (code) => {
    console.log(`child process exited with code ${code}`);
    if (code == 0) {
        console.log('OpenMW exited normally');
        process.exit(0);
    }
});

// Server communication
// Sockets
socket.on('connect', async () => {
    console.log('Connected to socket server');
});

socket.on('wanderersData', (newWanderers) => {
    console.log('Received Wanderers list:', newWanderers);
    wanderers = newWanderers;
    writeYamlToFile(wanderersFilePath, wanderers);
});

socket.on('wandererUpdated', (updatedWanderer) => {
    console.log('Other Wanderer updated:', updatedWanderer);
    const index = wanderers.findIndex(w => w.id === updatedWanderer.id);
    if (index !== -1) {
        wanderers[index] = updatedWanderer;
    } else {
        wanderers.push(updatedWanderer);
    }
    writeYamlToFile(wanderersFilePath, wanderers);
});

