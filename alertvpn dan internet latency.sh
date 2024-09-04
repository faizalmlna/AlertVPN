# Variable yang dibutuhkan

:local vpnNames {"namavpn"; "vpn_to_v7_2"};
:local vpnAddresses {"ipremote"; "30.40.50.1"};
:local internet "8.8.8.8";
:local ms 25;  # treshold untuk ke VPN
:local vpnavgRtt; # mengambil rata rata ping ke VPN
:local vpnReceived; # mengambil jumlah packet yang diterima ke VPN
:local intAvgRtt; # mengambil rata-rata ping ke internet
:local intReceived; #mengambil jumlah packet yang diterima ke Internet
:local intms 20;  # treshold ping ke internet

# Mengambil nama router
:local routerName [/system identity get name]

# Loop mengecek kondisi VPN dan internet
:for i from=0 to=([:len $vpnNames] - 1) do={
    :local vpnName [:pick $vpnNames $i];
    :local address [:pick $vpnAddresses $i];
# Mengecek kondisi VPN
    /tool flood-ping $address count=10 do={
        :if ($sent = 10) do={
            :set vpnavgRtt $"avg-rtt"
            :set vpnReceived $"received"
        }
    }

    # Mengecek kondisi internet 
    /tool flood-ping $internet count=10 do={
        :if ($sent = 10) do={
            :set intAvgRtt $"avg-rtt"
            :set intReceived $"received"
        }
    }

    # Alert jika latency VPN di atas yang ditentukan
    :if (($vpnavgRtt >= $ms) && ($vpnReceived = 10)) do={
        /tool fetch url=("https://api.telegram.org/bot6969678697:AAEaF6D7BTvhjB7pfzYpScdhYcFLKVRM_XE/sendMessage?chat_id=(idTelegram)&text=WARNING dari $routerName: Koneksi VPN $vpnName memiliki rata-rata ping $vpnavgRtt ms") keep-result=no
    }
   # Alert jika terjadi packet loss pada VPN
    :if (($vpnReceived < 9) && ($vpnReceived > 1)) do={
        /tool fetch url=("https://api.telegram.org/bot6969678697:AAEaF6D7BTvhjB7pfzYpScdhYcFLKVRM_XE/sendMessage?chat_id=(idTelegram)&text=WARNING  dari $routerName: terjadi packet loss ke $vpnName ($address). Packet yang diterima hanya $vpnReceived dari 10 packet. Link ke internet memiliki latency $intAvgRtt ms") keep-result=no
    }

    # Alert jika kondisi VPN putus dan internet aman
    :if (($vpnReceived = 0) && ($intReceived > 0)) do={
        /tool fetch url=("https://api.telegram.org/bot6969678697:AAEaF6D7BTvhjB7pfzYpScdhYcFLKVRM_XE/sendMessage?chat_id=(idTelegram)&text=WARNING  pada $routerName: terjadi DOWNTIME ke $vpnName ($address), namun koneksi ke internet aman dengan latency $intAvgRtt ms") keep-result=no
    }
    
    # Alert jika keduanya putus
    :if (($vpnReceived = 0) && ($intReceived = 0)) do={
        /tool fetch url=("https://api.telegram.org/bot6969678697:AAEaF6D7BTvhjB7pfzYpScdhYcFLKVRM_XE/sendMessage?chat_id=(idTelegram)&text=CRITICAL  pada $routerName: terjadi DOWNTIME ke $vpnName ($address) dan ke arah internet ($internet)") keep-result=no
    }


   # Alert jika kondisi internet di atas threshold latency
    :if (($intAvgRtt >= $intms) && ($intReceived = 10)) do={
        /tool fetch url=("https://api.telegram.org/bot6969678697:AAEaF6D7BTvhjB7pfzYpScdhYcFLKVRM_XE/sendMessage?chat_id=(idTelegram)&text=CRITICAL pada $routerName: Koneksi ke internet terpantau tinggi dengan $intAvgRtt ms") keep-result=no
    }
    # Alert jika terjadi packet loss pada internet
    :if (($intReceived < 9 ) && ($intReceived > 1)) do={
        /tool fetch url=("https://api.telegram.org/bot6969678697:AAEaF6D7BTvhjB7pfzYpScdhYcFLKVRM_XE/sendMessage?chat_id=(idTelegram)&text=WARNING pada $routerName: terjadi packet loss ke $internet. Packet yang diterima hanya $intReceived dari 10 packet dengan latency $intAvgRtt ms") keep-result=no
    }
}

