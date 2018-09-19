sdb_exists=$(lsblk | grep sdb)
if [ -z "$sdb_exists" ]; then
        echo 'sdb does not exist.'
        exit
fi

sdc_exists=$(lsblk | grep sdc)
if [ -z "$sdc_exists" ]; then
        echo 'sdc does not exist.'
        exit
fi

# Create kodethon user
sudo useradd -m kodethon
usermod -aG sudo kodethon
echo 'kodethon ALL=(ALL) NOPASSWD:ALL' | sudo tee -a /etc/sudoers

# Install ZFS
sudo apt install zfsutils-linux 
sudo zpool create -f zpool-docker /dev/sdb 
sudo zfs create -o mountpoint=/var/lib/docker zpool-docker/docker
sudo zpool create -f kodethon /dev/sdc
sudo zfs create -o mountpoint=/home/kodethon/production kodethon/production
sudo zfs create -o mountpoint=/home/kodethon/production/drives kodethon/production/drives
sudo zfs create -o mountpoint=/home/kodethon/production/system kodethon/production/system
sudo chown -R kodethon:kodethon /home/kodethon/production

# Install applicaiton files
cd /home/kodethon/production && \
        sudo -u kodethon git clone https://github.com/Jvlythical/CDE-Node.git && \
        sudo -u kodethon mv CDE-Node/* . && sudo -u kodethon rmdir CDE-Node

# Install Docker
sudo apt-get update
sudo apt-get install     apt-transport-https     ca-certificates     curl     software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) \
        stable"
sudo apt-get update
apt-cache docker-ce
apt-cache madison docker-ce
sudo apt-get install docker-ce=17.09.0~ce-0~ubuntu
sudo usermod -aG docker jvlarble

# Update docker config to use zfs storage driver
echo "{\n\"storage-driver\": \"zfs\"\n}" | sudo tee /etc/docker/daemon.json

sudo su - kodethon