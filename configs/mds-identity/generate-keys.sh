#!/usr/bin/env sh

echo 'some-password' > pass
rm -f ./key ./key.pub ./key.pub.pem
ssh-keygen -f ./key -b 4096 -m PEM -n $(cat pass)
ssh-keygen -f ./key.pub -e -m pem > key.pub.pem
