const express = require('express');
const app  = express();
const path = require('path');
const fs = require('fs');
const mysql = require('mysql');
const dbConfig = require('./db.config.js');
const mqtt = require ('mqtt');
const client = mqtt.connect('mqtt://localhost/1883')
const serverPort = 8000;

app.use(express.json());

const connection = mysql.createConnection({
	host: dbConfig.HOST,
	user: dbConfig.USER,
	password: dbConfig.PASSWORD,
	database: dbConfig.DB,
	charset: 'utf8mb4'
});

connection.connect(error => {
	if(error) throw error;
	console.log("Succesfully connected to the database");
});

client.on('connect', function() {
	client.subscribe('#', function(err) {return});
});

client.on('message', function(topic, mes) {
	const splitTopic = topic.split('/');
	const device = splitTopic[0];
	const subtopic = splitTopic[1];
	const message = JSON.parse(mes.toString());
	console.log(message);
	connection.query('SELECT id FROM Devices WHERE deviceID = ?', [device], (err, res) => {
		if(res.length === 0) {
			// Device does not exist
			connection.query('INSERT INTO Devices(deviceID, deviceName, imagePath) VALUES(?,?,?)', [device, device, device], (err, res) => {});
		}
		const date = new Date();
		const time = date.getFullYear() + "-" + (date.getMonth() + 1) + "-" + date.getDate() + " " + date.getHours() + ":" + date.getMinutes() + ":" + date.getSeconds();
		connection.query('INSERT INTO Data(deviceID, temperature, airHumidity, soilMoisture, recievingLight, time) VALUES(?,?,?,?,?,?)', [device, message.temperature, message.airHumidity, Math.round(message.soilMoisture * 100), message.recievingLight, time], (err, res) => {});
	});
});

app.get('/', (req, res) => {
	res.send('Server is running bro! Happy hacking :)');
});

app.get('/api/devices', (req, res) => {
	connection.query('SELECT * from Devices', (err, result) => {
		if(err) {
			res.send({message: error, payload: err});
		}
		if(result.length) {
		// TODO: Send devices data
			res.send({message: result.length + " devices found", payload: result});
		} else {
			res.send({message: "No devices found", payload: null});
		}
	});
});

app.get('/api/devices/:deviceID', (req, res) => {
	const deviceID = req.params.deviceID;
	connection.query('SELECT AVG(temperature) AS temperature, AVG(airHumidity) AS airHumidity, AVG(soilMoisture) AS soilMoisture FROM Data WHERE deviceID = ? AND time > date_sub(now(), interval 1 day) GROUP BY hour(time)', [deviceID], (err, result) => {
		res.send({message: 'Query OK!', payload: result});
	});
});

app.put('/api/devices/update', (req, res) => {
	const deviceID = req.body.deviceID;
	const name = req.body.name;
	const species = req.body.species;
	const mode = req.body.mode;
	const waterPeriod = req.body.waterPeriod;
	const humidityThreshold = req.body.humidityThreshold;
	connection.query('UPDATE Devices SET deviceName = ?, plantSpecies = ?, mode = ?, waterPeriod = ?, humidityThreshold = ? WHERE deviceID = ?', [name, species, mode, waterPeriod, humidityThreshold, deviceID], (err, response) => {
		if(err) throw err;
		client.publish(deviceID + '/actionData', JSON.stringify({mode:mode, waterPeriod:parseInt(waterPeriod), humidityThreshold:parseInt(humidityThreshold)}), {retain: true});
		res.send({message: 'Update on ' + deviceID + ' OK!'});
	});
});

app.listen(serverPort, () => {
	console.log(`Example app listening at http://localhost:${serverPort}`);
});
