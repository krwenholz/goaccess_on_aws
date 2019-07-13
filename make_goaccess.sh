# From the perspective of the docker image
cd build
yum install wget GeoIP-devel -y
wget https://tar.goaccess.io/goaccess-1.3.tar.gz
tar -xzvf goaccess-1.3.tar.gz
cd goaccess-1.3/
./configure --enable-utf8 --enable-geoip=legacy
make
mv goaccess ..
cd ..
rm -rf goaccess-1.3*
