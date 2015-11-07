#
# vim:sw=2 ts=8:et sta
#
#  $MyBSD: src/gelojoh/README.TXT,v 1.3 2003/07/31 19:36:41 skywizard Exp $
#

Gelojoh Web Server IPv4/IPv6
----------------------------
(menggunakan Dejiko Multiplexer Framework)

    Ini ialah Gelojoh Web Server (nama gonjol: Tomoyo/Dejiko chan),
    ditulis 100% menggunakan bahasa pengaturcaraan Ruby
    (http://www.ruby-lang.org) berasaskan Dejiko Multiplexer Framework
    (yang semestinya aku tak ada masa nak explain, kecuali dengan
    permintaan). Webserver ini sangat mudah/simple dan cukup makan utk.
    mereka yang sekadar mahu memaparkan file yang statik sahaja (bukan
    CGI/PHP). 

	
(Dejiko , dengan gaya yang gonjol gelabah mengada-ngada)

Features/Ciri-ciri
------------------
   1. Ditulis 100% menggunakan bahasa Ruby (version 1.8.x) 2. GET/HEAD,
      HTTP/1.1 keep-alive / chunked transfer encoding / bytes range
      (support resume download).
   3. BSD/Linux/Unix , Microsoft Windows 95/98/NT/2000/XP/Server2003
      (asalkan boleh install/run ruby).
   4. Dual-stack operation (IPv4/IPv6).
   5. Directory indexing, sama macam Apache.
   6. Single threaded, menggunakan select() utk. me'multiplex'kan
      beratus-ratus (nak ikutkan mau beribu juga) connection.
   7. Tersangat simple/stupid, bila-bila masa boleh run sesuka hati tanpa
      pening-pening kepala nak install webserver yang merepek meraban.
   8. Sesuai utk. mereka yang tetiba nak "share" file dengan sesapa, run,
      terus org. lain boleh access/download file.  9. Path Aliasing, sama
      macam Apache 10. Laju! Mantap! Geram!

Penulis/Author
--------------
Penulis / pengarang / programmer ni menuntut agar dirinya disembunyikan
dari pengetahuan umum, atau pengetahuan umum disembunyikan daripada
penulis, atau tulisan membunyikan bunyi kambing kepada umum, atau
pengumuman ditulis secara bunyi-bunyian.

Lesen/License
-------------
My(BSD) Copyright.

Requirement/Keperluan
---------------------
Ruby version 1.8.0

Installation/Pemasangan (Unix/Windows)
-------------------------------------
   1. Extract distribution gelojoh ke mana-mana directory
   2. Copy file gelojoh.conf.sample jadi gelojoh.conf dan
      baca / fahamkan / edit file tersebut
   3. Unix
      ----
      # ruby gelojoh.rb
      (Bagi Unix, proses ini akan drop jadi "nobody").
  
      Windows
      -------
      C:\> C:\mana\ruby\ko\ruby.exe gelojoh.rb

Isu
---
   1. AHHHH!!!!! Bila aku browse directory, apa pasal icon folder apa
      semua takda!
      Hehehe.. puncanya ialah dia tak dapat carik mana path
      /images/ . Ko ada 2 pilihan:-
	 1. copy seluruh directory images/ (yang disertakan sekali) ke
	    docroot. ATAU
	 2. Guna alias feature, utk. alias'kan path /images/ ke path yang
	    sebenar [Tengok ISU bawah]

   2. Macam mana nak set alias?
      Edit gelojoh.conf , tengok bab Alias dan fahamkan
      bebetul.

   3. Mana nak dapatkan ruby? (Windows)
      Ruby Win32 installer (version 1.8.0 ya!) yang rasmi boleh didapati
      di sourceforge ATAU , kalau nak gunakan yang IPv6 punya, boleh amik
      yang MyBSD punya (menggunakan MinGW). Kalau nak guna yang MyBSD
      punya, simple sahaja:- 
         1. Download
         2. Extract/Unzip ke mana-mana directory, kemungkinan C:\
	 3. C:\ruby\bin\ruby.exe -v (Output dia lebih kurang "ruby 1.8.0
	    2002-06-20 [i386-mingw32]")
      Ruby binary yang MyBSD punya ni simple sahaja, basic (full
      featured!) ruby. Cuma yang jadi extra tu pasal socket library dia
      support IPv6 (bagi windows yang ada IPv6 stack). Kalau takda IPv6
      stack pun takpa, boleh jalan juga, sayang manja.

   4. Macam mana aku nak bind webserver ni kat semua address aku?
      Gunakan global address 0.0.0.0 (IPv4), atau, kalau nak bind ke
      semua address termasuk IPv6 , guna "::" (AWAS: tak semua os support
      bendalah ni, nama dia IPv6 wildcard). Tak semestinya bind ke ip,
      bind ke hostname pun boleh juga. Gelojoh dengan secara bijak
      memandai akan detect capability address. Kalau nak check apa
      capability address/ip tu, cuba gunakan utility "lookup.rb", yang
      disertakan sekali.

   5. IPv6 atas Windows????!?!?!??!?!
      Ya! Windows pun support IPv6 stack! Terutamanya Windows XP. Windows
      2000 pun support. NT 4 (ntah, cuba check), Win95/98/Me = NO!. So
      kalau korang XP, IPv6 memang dah sedia ada, cuma tak di'aktif kan
      lagi. (Tak larat aku nak bebel, kalau ada yang demand, nanti aku
      explain ya sayang honey).

   6. Benda ni apasal kalau run tercongok depan aku, apasal tak run kat
      background?
      Benda ni memang dibuat camtu, supaya korang tercongok termenung kat
      depan monitor macam kambing tunggu nak masuk kandang, atau kandang
      tunggu nak masuk kambing.

      Hah.. kalau nak run kat backgound boleh juga, salah satu caranya:-

      Unix
      ----
      ruby gelojoh.rb > apa_saja_la_logfile.log 2>&1 &
      (gelojoh.sh disertakan, sebagai contoh)

      Windows
      -------
      He he he he... nanti dulu la ya sayang... buat masa ni redha je
      lah..

   7. Aku takda masa nak guna, takda masa nak memuaskan nafsu menggunakan
      benda tak berfaedah ni... tapi... SHOW ME THE CODE DAMN IT!
	 1. core.rb : Dejiko Multiplexer Framework crap crap crap too
	    crap to be crap.
         2. ioutil.rb : IO utility.
         3. gelojoh.rb : Gelojoh Web Server.
         4. mime.types : MIME types dari Apache.
         5. images/ : Icon / images.

   8. Macam nak kill benda ni?
      Kalau kat Unix, boleh Ctrl+C , kalau kat Win2000/XP/NT, bukak task
      manager, kill proses ruby.exe, kalau kat Win95/98 ,
      Ctrl+Alt+Delete, End Task ruby. (dekat windows boleh juga Ctrl+C,
      tapi dia hang lama sikit..)

   9. Kenapa nama dia Gelojoh?
      Nama sebenar bendalah ni ialah Tomoyo/Dejiko chan, tapi disebabkan
      semua org. beridolakan ded1 (dan juga suara ramai), maka nama
      Gelojoh dipilih. Gelojoh sangat sesuai dengan ded1 yang sememangnya
      gelojoh, nafsu meluap-luap membuak-buak tak tentu arah.

  10. Apa hubungan Tomoyo , Dejiko dgn. Gelojoh ni
      Hubungan sulit. Hubungan yang penuh cinta taik kucing, dan taik
      ded1 juga.

  11. Kenapa perlunya adakan support utk. Windows (tm)? Kata pro open
      source, tapi buat benda yang menguntungkan benda yang tak open
      source plak. Tak Open Source betul!
      Pendapat sebegini aku biarkan sebagai senaman/exercise utk.
      badut-badut moron taik kucing tembelik acjhor yang sebegini juga.

  12. Reliable / kebolehpercayaan kah Gelojoh ni?
      Ntah dan Ntah juga.

  14. Hmmm.. aku menyampah / benci IPv6.. sia-sia, tak perlu, mengada-ngada
      Ko fikir ko la raja pembenci IPv6 ya? SALAH. "AKU" adalah MAHARAJA
      PEMBENCI IPv6. Aku boleh sebut 10 juta perkataan yang berbeza merujuk
      kepada kebencian aku yang teramat-amat terhadap IPv6 yang crap potato ni.
    
      Sebenarnya, IPv6 merupakan penyelamat kepada seluar dalam korang semua.
      Muatan IPv6 jauh lebih besar / panjang berbanding IPv4. Kalau IPv4 tu
      ibarat 1 cm , IPv6 ni ibarat jarak antara bumi dengan planet pluto.
      Korang mungkin fikir "ah.. IPv4 masih cukup, takda pun kes kekurangan IP"
      , tapi cuba fikir, apa guna NAT merepek tu? Bukan ke korang terpaksa
      mengeNAT disebabkan korang tak dapat IP? IPv6 memberikan peluang "true
      end-to-end" connection, kerana semua orang dah boleh ada ip sendiri tanpa
      perlu NAT. Memang la ko boleh kata sekarang ni tak perlu, SEBABNYA BELUM
      ADA TRAGEDI YANG SERIUS KEKURANGAN IP. Kenapa? IPv6 telah menyebabkan
      tragedi sebegitu rupa tak menjadi, dan seperti biasa, manusia ni selagi
      takda tragedi, selagi tu lah tak ingat apa-apa. 

Sebarang pertanyaan / ugutan / cacian / makian / taik'kan / kambing'an /
katak'an boleh dibuat melalui <skywizard at MyBSD dot org dot my> , atau
berkenaan IPv6, kepada <drl at MyBSD dot org dot my>. 
