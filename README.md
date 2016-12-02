# homewizard-web-remote
script to remote control the homewizard (www.homewizard.de) from bash

## setup
#### open the script in an editor and:
   * set the ip address to your homewizard
   * set your password
   
#### install the required packages (for debian, may work on ubuntu too)
```
apt-get install jq wget
```
   
## using the script
some examples:
#### get **t**emperature from weather **d**evice
```
./homewizard.sh -t -d ThermoWohnraum
```

#### get **h**umidity from weather **d**evice
```
./homewizard.sh -h -d ThermoWohnraum
```

#### **g**et state of **d**evice
```
./homewizard.sh -g -d Flur
```

#### **s**witch **d**evice on
```
./homewizard.sh -d Flur -s on
```

#### **s**witch **d**evice off
```
./homewizard.sh -d Flur -s off
```

## some words about security
*keep in mind: the connection to homewizard is http only -> no security! your password will be transmitted without encryption. Use only in your private WLAN.*

## credits
I got the information about the homewizard urls from this website: http://wiki.td-er.nl/index.php?title=Homewizard
