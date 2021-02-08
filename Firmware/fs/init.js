load('api_config.js');
load('api_sys.js');
load('api_gpio.js');
load('api_timer.js');
load('api_rpc.js');
load('api_mqtt.js');
load('api_dht.js');
load('api_adc.js');

// ANCHOR: Definición de pines

let led = Cfg.get('app.output.led');
let dhtPin = Cfg.get('app.input.dht');
let adcPin = Cfg.get('app.input.adc');
let motorPin = Cfg.get('app.output.motor');
let lightPin = Cfg.get('app.input.light');

let deviceID = Cfg.get('device.id');

let dht = DHT.create(dhtPin, DHT.DHT11);

GPIO.set_mode(led, GPIO.MODE_OUTPUT);
GPIO.set_mode(motorPin, GPIO.MODE_OUTPUT);
GPIO.set_mode(lightPin, GPIO.MODE_INPUT);
let adcEnable = ADC.enable(adcPin);

// ANCHOR: Definición de variables

let wfCon = {connected: false, indicatorTimer: 0, connStatus: ffi('char *mgos_wifi_get_status_str(void)')};
let prgmData = {mode: null, waterPeriod: null, humidityThreshold: null};
let waterOnTimer = 0;
let waterOffTimer = 0;

// ANCHOR: Definición de funciones

function checkWifiConnection() {
    wfCon.indicatorTimer = Timer.set(250, true, function() {
        GPIO.toggle(led);
        if(wfCon.connStatus() === 'got ip') {
            Cfg.set({mqtt: {will_message: "Disconnected", will_topic: (deviceID + '/disconnect')}});
            GPIO.write(led, 0);
            wfCon.connected = true;
            Timer.del(wfCon.indicatorTimer);
        }
    }, null);
}

function getData() {
    let data = {temperature: dht.getTemp(), airHumidity: dht.getHumidity(), soilMoisture: 0, recievingLight: false};
    data.soilMoisture = 1 - (ADC.read(adcPin) / 1024);
    data.recievingLight = GPIO.read(lightPin) === 1 ? false : true;
    return data;
}

function resetWifiConfig() {
    let data = {
        config: {
            wifi: {
                sta: { enable: false, ssid: "", pass: ""},
                ap: { enable: true }
            }
        }
    };
    RPC.call(RPC.LOCAL, 'Config.Set', data, function(resp, ud) {
        RPC.call(RPC.LOCAL, 'Config.Save', {reboot: true}, function(resp, ud) {return;}, null);
    }, null);
}

function sendData() {
    MQTT.pub((deviceID + '/data'), JSON.stringify(getData()), 0, true);
    // If mode is auto check humidityThreshold value to activate pump
}

// ANCHOR: Inicio del programa

// ** Apagar salida de bomba de agua
GPIO.write(motorPin, 0);
////////////////////////////////

if(adcEnable === 1) {
    checkWifiConnection();
    Timer.set(5000, true, function () {
        if(!wfCon.connected) { return ;}
        sendData();
        if(prgmData.mode === 'manual') { return; }
        if((1 - (ADC.read(adcPin) / 1024)) < (prgmData.humidityThreshold / 100)) {
            GPIO.write(motorPin, 1);
        } else {
            GPIO.write(motorPin, 0);
            // Save water time
        }
    }, null);
    MQTT.sub((deviceID + '/actionData'), function(conn, topic, msg) {
        let data = JSON.parse(msg);
        GPIO.write(motorPin, 0);
        if(prgmData.mode === data.mode && prgmData.waterPeriod === data.waterPeriod && prgmData.humidityThreshold === data.humidityThreshold) { return; }
        prgmData.mode = data.mode;
        prgmData.waterPeriod = data.waterPeriod;
        prgmData.humidityThreshold = data.humidityThreshold;
        if(waterOnTimer !== 0) {
            Timer.del(waterOnTimer);
            Timer.del(waterOffTimer);
            waterOnTimer = 0;
            waterOffTimer = 0;
        }
        if(prgmData.mode === 'manual') {
            let seconds = 1000 * 86400 * prgmData.waterPeriod;
            waterOnTimer = Timer.set(seconds, true, function() {
                GPIO.write(motorPin, 1);
            }, null);
            waterOffTimer = Timer.set(seconds + 10000, true, function() {
                GPIO.write(motorPin, 0);
                // Save water time
            }, null);
        }
    }, null);
    MQTT.sub((deviceID + '/water'), function(conn, topic, msg) {
        GPIO.write(motorPin, 1);
        Timer.set(10000, false, function() {
            GPIO.write(motorPin, 0);
        }, null);
    }, null);
    RPC.addHandler('Wifi.Reset', function(args) {
        resetWifiConfig();
        return { reset: 'Ok' };
    });
} else {
    print('Fallo en ADC enable');
    GPIO.write(led, 0);
}
