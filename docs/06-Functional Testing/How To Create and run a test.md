# How to create a functional test

## 1. Create a godot project

The first step is to create a godot project. This project must be minimaliste and only test one feature (input sending and recive, spawn entity...).
This Scene will print console log that will be catch by the testing script.

## 2. Update the yaml file

The yaml file is composed of a list of test, here is an exemple of test:

```
tests:
    - name: "Test 1"
        path: "./template/"
        timeout: 30
        server:
            number: 2
            wait-string: "Press Space to exit..."
            delay: 3

        client:
            number: 1
            wait-string: "Container is ready!"
            delay: 3

        expects:
            servers:
                1:
                - "JUMP"
                2:
                - "JUMP"

            clients:
                1:
                - "press: move forward"
                - "release: move forward"
                - "press: move left"
                - "release: move left"
                - "press: move right"
                - "release: move right"
                - "press: move back"
                - "release: move back"
                - "press: jump"
                - "JUMP"
```

You will find in the yaml:

* Name     : name of the test
* Path       : path to the godot project previouselly created
* Timeout : if all the match are not find by the time limit it will considerate the test failed
* Server/Client  :
* * Number : number of server to up
* * Wait-String : when this string is matched we will create a new server or client
* * Delay : is the delay between 2 creation of server
* Expects :
* * Servers : Contain a list of server, each of them have a list of string to match
* * Clients : Contain a list of server, each of them have a list of string to match

## 3. Run the new created test
!! Be sure to have redis, pulsar and master running !!
You can use ```./automation/run --redis/pulsar/master``` in celte-system

Now that you have updated the yaml file and created the godot project you can launch the test using "./autotest" his first argument must be the yaml file

```
./autotest config.yaml
```

The STDOUT and STDERR of all the process (client/servers) can be find in "test_logs"

![1742100678003](image/HowToCreateandrunatest/1742100678003.png)
