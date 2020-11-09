load('api_config.js');
load('api_gpio.js');
load('api_timer.js');
load('api_rpc.js');

let led = Cfg.get('app.output.led');

GPIO.set_mode(led, GPIO.MODE_OUTPUT);

let wfCon = {connected: false, indicatorTimer: 0, connStatus: ffi('char *mgos_wifi_get_status_str(void)')};

function checkWifi() {
    wfCon.indicatorTimer = Timer.set(250, true, function() {
        GPIO.toggle(led);
        if(wfCon.connStatus() === 'got ip') {
            GPIO.write(led, 0);
            Timer.del(wfCon.indicatorTimer);
        }
    }, null);
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
        print('Wifi configuration reset!\nResponse: ' + JSON.stringify(resp));
        RPC.call(RPC.LOCAL, 'Config.Save', {reboot: true}, function(resp, ud) {
            print('Rebooting...\nResponse: ' + JSON.stringify(resp));
        }, null);
    }, null);
}

RPC.addHandler('Wifi.Reset', function(args) {
    resetWifiConfig();
    // let c2 = RPC.call(RPC.LOCAL, 'Config.Save', {reboot: true}, function(resp, err_code, err_msg, ud) {
    //     if (err_code !== 0) {
    //         print("Error: (" + JSON.stringify(err_code) + ') ' + err_msg);
    //     } else {
    //         print('Rebboting...');
    //     }
    // }, null);
    return { reset: 'Ok' };
});

checkWifi();
