# Limitacion stateless: ADMIN hace ping a un invitado.
# El request llega, pero la respuesta del invitado se descarta en p4sw3.
# Se ejecuta en pc_admin1
echo "===== Ping de pc_admin1 a pc_guest1 ====="
ping -c 3 -W 1 10.19.2.2 2>&1 | tee /shared/2_3-stateless-admin-a-guest.txt
