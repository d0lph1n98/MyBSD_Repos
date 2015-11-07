#
# vim:sw=2 ts=8:et sta
#
#  $MyBSD: src/gelojoh/SSLREADME.TXT,v 1.2 2004/05/16 14:17:35 skywizard Exp $
#

Gelojoh Dan SSL
---------------
Wohoooooo.. dengan ini diisytiharkan bahawasanya Gelojoh telah support
SSL (walaupun masih bengap). Buat masa ni, SSL cuma ada atas Unix (BSD /
Linux) sahaja. Sorry, win32.


Cara nak mengSSLkan Gelojoh
---------------------------
Rujuk gelojoh.conf.sample, berkenaan 'ListenSSL', 'SSLCertificate' dan
'SSLKey'. Walau macam mana pun, kena generate server key, juga, haha,
baca seterusnya.

Server Key
----------
Hm.. ini cara paling bengap dan tak senonoh untuk generate server key. By
default, kalau ko tak declare SSLCertificate/SSLKey , atau kedua-dua
directive tu tak valid, Gelojoh dengan bijak/bengap akan auto-generate
server key dan berlagak sebagai CA. Sama ada:
  1) Ko nak dia auto-generate
  2) Ko nak generate sendiri, walaupun merepek
  3) Mintak dengan Verisign atau mana-mana CA bertauliah
  
So? Nak generate sendiri? bagus... macam ni, gunakan 'gencert.sh' yang
disertakan, dan juga edit 'ssl.cnf' sesuka hati. Lepas tu:

  ./gencert.sh ssl.cnf yada.crt yada.key

Memang bengap, kan? Hah.. lepas tu, pergi edit gelojoh.conf. Pastikan SSL
directive diisi dengan betul, dan ListenSSL *mesti* ada/betul. hah.. hah...

ph34r t3h 55L.
