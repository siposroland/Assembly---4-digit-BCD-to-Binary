
	
; Bemenetek: 
; R0 - BCD alsó 2 digit
; R1 - BCD felső 2 digit

; Kimenetek:
; R2 - Bináris alsó 8 bit
; R3 - Bináris felső 8 bit (alapvetően csak 6-ra lenne szükség, tehát a 7-es és 6-os bit az eredményben 0)
; F0 - Helytelen BCD bemenetek (F0 = 1 hiba volt, F0 = 0 nem volt hiba)
; hiba esetén az eredmény regiszterek értéke darabonként: 0xFFh 
	
; Rontás:
; R2 és R3 regiszterek (eredmény)
; F0 flag (hibajelzés)
	
	ORG 0h
Main:

; Kezdőértékek megadása
	MOV R0, #99H				; kezdeti értékek megadása
	MOV R1, #99H				; kezdeti értékek megadása
	ACALL BcdToBin				; ugrás az átalakító szubrutinra
Vegtelen:						; végtelen ciklus
	SJMP Vegtelen
	
	

	ORG 200h
	
BcdToBin: 

; KEZDETI ÉRTÉKEK MENTÉSE

	PUSH PSW					; flagek mentése
	PUSH 0						; regiszterek mentése
	PUSH 1
	PUSH 4
	PUSH 7
	PUSH ACC
	PUSH B

	
; ÁTALAKÍTÁS 1. (előkészületek) és ELLENŐRZÉS (1. digit van csak)

; A 4 BCD digit elosztása R0...3 regiszterek között (a regiszterek alsó 4 bitjén helyezkednek majd el)
; R3 -> 4. digit
; R2 -> 3. digit
; R1 -> 2. digit
; R0 -> 1. digit

; A nagyobb helyiértékektől a kisebbek felé haladok
; így nem rontom el a még át nem írt digiteket (mivel használom a tartalmazó regisztereket is)

; F0-val jelezem, hogy a legfelső 3 digit 0 értékű: F0 addig 0, amíg a digitek "üresek", az 1. digithez érve kiderül,
; hogy a előállt e az eredmény, hiszen 1 digiten a BCD = Bináris érték
	CLR F0						; F0 beállítása 0 értékre


; 4. digit elhelyezése R3-ban
	MOV A, R1		 			; R1 felső 4 bitjére van szükségem
	ANL A, #11110000b 			; ezeket kimaszkolom egy ÉS-eléssel, ami az alsó 4 bitet 0-ra változtatja
	JZ Digit4					; F0 beállítása Z értéke alapján
	SETB F0
Digit4:
	RL A						; 4x elforgatom, hogy a felső 4 bit az alsó 4 helyére kerüljön
	RL A 
	RL A
	RL A
	MOV R3, A					; 4. digit elmentése R3 regiszterben
; BCD tartomány ellenőrzése:
	ANL A, #00001000b			; a legfelső helyiérték maszkolása, ha ez 0, akkor Z = 1, egyébként Z = 0
								; amennyiben ez az érték 1, az őt követő bitek csak 001 vagy 000 lehetnek,
								; tehát meg kell vizsgálni, hogy: bitsorozat == 00X (ahol X = dontcare)
	JZ 	BcdOk3					; Z = 0 esetén a szám 0...8 lehet, ekkor BCD tartományon belül van, folytatódhat a program
								; egyébként tovább kell ellenőrizni
	MOV A, R3					; visszatöltöm a vizsgálandó értéket
	ANL A, #00000110b			; a vizsgálandó 2 helyiértéket maszkolással kiválasztom
								; akkor helyes a szám tartománya, ha ekkor a Z flag 1 lesz, tehát mindkettő 0
	JZ 	Atlep1					; hiba esetén vége a futásnak, egyébként folytatódik a program futása
	JMP VegeHiba				; out of range hiba kezelése
Atlep1:


; 3. digit elhelyezése R2-ben
BcdOk3:
	MOV A, R1					; R1 alsó 4 bitjére van szükségem
	ANL A, #00001111b 			; ezeket maszkomom és ÉS-elem, így a felső 4 bit lesz 0						
								; nem kell forgatni, az alsó 4 biten vannak az értékek
	JZ Digit3					; F0 beállítása Z értéke alapján
	SETB F0
Digit3:
	MOV R2, A					; a 3. digitet tárolom R2 regiszterben
								; BCD tartomány ellenőrzése: az előzőekkel megegyező működés
	ANL A, #00001000b			; a legfelső helyiérték maszkolása, ha ez 0, akkor Z = 1, egyébként Z = 0
								; amennyiben ez az érték 1, az őt követő bitek csak 001 vagy 000 lehetnek,
								; tehát meg kell vizsgálni, hogy: bitsorozat == 00X (ahol X = dontcare)
	JZ 	BcdOk2					; Z = 0 esetén a szám 0...8 lehet, ekkor BCD tartományon belül van, folytatódhat a program
								; egyébként tovább kell ellenőrizni
	MOV A, R2					; visszatöltöm a vizsgálandó értéket
	ANL A, #00000110b			; a vizsgálandó 2 helyiértéket maszkolással kiválasztom
								; akkor helyes a szám tartománya, ha ekkor a Z flag 1 lesz, tehát mindkettő 0
	JZ 	Atlep2					; hiba esetén vége a futásnak, egyébként folytatódik a program futása
	JMP VegeHiba				; out of range hiba kezelése
Atlep2:				

; 2. digit elhelyezése R1-ben
BcdOk2:
	MOV A, R0					; R0 felső 4 bitjére van szükségem
	ANL A, #11110000b 			; ezeket kimaszkolom egy ÉS-eléssel, ami az alsó 4 bitet 0-ra változtatja
	JZ Digit2					; F0 beállítása Z értéke alapján
	SETB F0
Digit2:
	RL A						; 4x elforgatva a felső 4 bitből az alsó 4 bit helyére kerül
	RL A 
	RL A
	RL A
	MOV R1, A					; a 2. digitet tárolom R1 regiszterben
								; (R1-ben tárolt 2 digitet már tároltam R3 és R2-ben, így nem okozok hibát)
								; BCD tartomány ellenőrzése: az előzőekkel megegyező működés
	ANL A, #00001000b			; a legfelső helyiérték maszkolása, ha ez 0, akkor Z = 1, egyébként Z = 0
								; amennyiben ez az érték 1, az őt követő bitek csak 001 vagy 000 lehetnek,
								; tehát meg kell vizsgálni, hogy: bitsorozat == 00X (ahol X = dontcare)
	JZ 	BcdOk1					; Z = 0 esetén a szám 0...8 lehet, ekkor BCD tartományon belül van, folytatódhat a program
								; egyébként tovább kell ellenőrizni
	MOV A, R1					; visszatöltöm a vizsgálandó értéket
	ANL A, #00000110b			; a vizsgálandó 2 helyiértéket maszkolással kiválasztom
								; akkor helyes a szám tartománya, ha ekkor a Z flag 1 lesz, tehát mindkettő 0
	JZ 	Atlep3					; hiba esetén vége a futásnak, egyébként folytatódik a program futása
	JMP VegeHiba				; out of range hiba kezelése
Atlep3:	
	
; 1. digit elhelyezése R0-ban
BcdOk1:
	MOV A, R0					; R0 alsó 4 bitjére van szükségem
	ANL A, #00001111b 			; a felsőket maszkolom és ÉS-eléssel nullázom
	MOV R0, A					; forgatás nélkül tárolom R0-ban az 1. digitet
; BCD tartomány ellenőrzése: az előzőekkel megegyező működés
	ANL A, #00001000b			; a legfelső helyiérték maszkolása, ha ez 0, akkor Z = 1, egyébként Z = 0
								; amennyiben ez az érték 1, az őt követő bitek csak 001 vagy 000 lehetnek,
								; tehát meg kell vizsgálni, hogy: bitsorozat == 00X (ahol X = dontcare)
	JZ 	BcdOk					; Z = 0 esetén a szám 0...8 lehet, ekkor BCD tartományon belül van, folytatódhat a program
								; egyébként tovább kell ellenőrizni
	MOV A, R0					; visszatöltöm a vizsgálandó értéket
	ANL A, #00000110b			; a vizsgálandó 2 helyiértéket maszkolással kiválasztom
								; akkor helyes a szám tartománya, ha ekkor a Z flag 1 lesz, tehát mindkettő 0
	JZ 	Atlep4					; hiba esetén vége a futásnak, egyébként folytatódik a program futása
	JMP VegeHiba				; out of range hiba kezelése
Atlep4:	
			
BcdOk:							; ide jutva kiderül, hogy minden digit BCD tartományba esett-e
								; itt ellenőrzöm, van-e az 1. digiten kívül nem 0 digit
								; F0 = 0 esetén van nem 0 értékű digit az 1. digiten kívül
	JB F0, Init					; ilyenkor tovább kell haladni
	MOV A, R0					; eredmény (1. digit) betöltése az eredmény-regiszterbe
	MOV R2, A					
	MOV R3, #0					; a további bitek betöltése
	SJMP VegeNincsHiba			; kilépés a szubrutinból, az eredmény előállt
	
	
; ÁTALAKÍTÁS 2. (BCD-ből Decimális szám)
	
	
; Az algoritmus futásának egyszerűsítéséhez 
; tízes számrendszerbeli számokból írom át a bináris értéket,
; az átalakításhoz a megfelelő értéket 2 regiszterben tárolom
; -> a felső 2 digitet az R1 regiszterben (decimális 0...99ig)
; -> az alsó 2 digitet az R0 regiszterben (decimális 0...99ig)
; Köztük kapcsolatot a Felső digitek páratlan esetében kell létrehozni,
; ekkor az Alsó digitekhez hozzáadok 100/2 = 50-et.
	
; Az 1-es és 10-es helyiértékek (ALSÓ) mentése R0-ba (alacsonyabb 2-vel kezdem, hogy ne rontsam R1-et)
Init:
	MOV A, R1					; az "ALSÓ" 10-es helyiérték betöltése
	MOV B, #10					; eltolás a 10-es helyiértékre szorzással 
								; (lehetséges ACC értékek = 90, 80, 70, ... , 10, 0)
	MUL AB
	ADD A, R0					; az "ALSÓ" 1-es helyiérték összeadása a 10-essel (ACC = 99, 98, 97, ... 2, 1, 0)
	MOV R0, A					; R0-ban tárolom az "ALSÓ" decimális értéket

; A "FELSŐ"-t azonos módon tárolom, mint az "ALSÓ"-t és páratlan értéke esetén
; a felezéséből származó +50 decimális értéket az "ALSÓ"-hoz adom,
; így hidalva át a 8 bites regiszterek (tárolás és műveletvégzés) 
; okozta problémát 16 bites számokon

; A 100-as és 1000-es helyiértékek (FELSŐ) mentése R1-bae
	MOV A, R3					; a "FELSŐ" 1000-es helyiérték betöltése
	MOV B, #10					; eltolás a 10-es helyiértékre szorzással (ACC = 9, 80, 70, ... , 10, 0)
	MUL AB
	ADD A, R2					; a "FELSŐ" 100-as helyiérték összeadása az 1000-essel (ACC = 99, 98, 97, ... 2, 1, 0)
	MOV R1, A

; ALAPÉRTÉKEK BEÁLLÍTÁSA
	
; Kezdőértékek megadása
	MOV R2, #0 					; az eredmény alsó bájtja
	MOV R3, #0					; az eredmény felső bájtja
	MOV R4, #1 					; megadja, hogy az eredmény regiszterekben melyik helyiértéknél tartunk (ott 1-es csak)
	CLR F0    					; F0 adja meg épp melyik (felső vagy alsó) regiszterbe kerüljön az aktuális ciklus eredménye
								; alsó (R2) -> F0 = 0 (alapbeállítás)
								; felső (R3) -> F0 = 1 (ha R4 túlcsordul, akkor vált)
	
; AZ ÁTALAKÍTÓ CIKLUS

; 1. Ellenőrzés ( 0-nál tartunk?)

; Mivel a legnagyobb ábrázolható számunk (9999d = 270Fh) 14 bites, így az "ALSÓ" és "FELSŐ" decimális
; értékek összeadásából maximum egy 15 bites szám keletkezhet, így az összeadással ellenőrzihető, 
; hogy be kell-e lépni a ciklusba vagy megvan az eredmény (alapértelmezetten az eredmény 0, tehát
; 0 esetén is jó az eredmény)
Ciklus:	
	MOV A, R0					;"ALSÓ" és "FELSŐ" összeadása
	ADD A, R1					
	JZ VegeNincsHiba  			; ha mindkét érték 0, akkor a Z flag 1-lesz, ekkor végeztünk 
								; egyébként be kell lépni a ciklusba

; 2. Az "ALSÓ" érték kezelése

; A legalsó bitet el kell juttatni az eredmény regiszterbe
; és amennyiben 1, kivonom belőle, hogy páros legyen
AlsoDecimal:
	MOV A, R0 					; "ALSÓ" betöltése
	ANL A, #1					; maszkoljuk úgy, hogy az akkumulátorban a legalacsonyabb helyiértéken
								; lévő bit maradjok csak
								; ha ez 0, akkor az egész akkumulátor 0 lesz, tehát Z = 1 esetén
								; páros szám van az "ALSÓ" regiszterben, e szerint kezeljük
	JZ AlsoParos				; átlépjük a páratlan esetet, ha páros (Z = 1)
	
AlsoParatlan:					; ha páratlan: 
	DEC R0						; csökkentjük az "ALSÓ" értékét (így osztható lesz 2-vel)
AlsoParos:						; ha páros:
								; nincs dolgunk vele

; 3. Eredmény tárolása

; - Az F0 flag mondja meg, hogy az alsó vagy felső regiszterben (R2 vagy R3 sorrendben) 
; tárolódjon az adott bit
; - Az R4 regiszter tartalmazza, hogy melyik bináris helyiértéken kell tárolni (csak ott 1-es)
; - Az akkumulátorban van éppen a regiszterbe tárolandó bit
	MOV B, R4 					; helyiérték betöltése a segédregiszterbe (szorzáshoz)
	MUL AB	 					; ezzel szorozva eltoljuk a megfelelő helyre a tárolandó bitet
	JNB F0, Also 				; F0-al kiválasztjuk melyik eredmény regiszterbe írjuk 
								; alsó => F0 = 0
								; felső => F0 = 1
								
; Csak a megadott helyiértéken van 1-es vagy 0-ás bit az akkumulátorban
; minden más érték 0
; Az eredményregiszterben ezen a helyen és fölötte is csak 0-ás értékek lehetnek
; tehát az összeadás csak az adott helyiértéken lévő bitet fogja megváltoztatni
Felso:
	ADD A, R3 					; eredmény hozzáadása a tárolandó bithez, ami a megfelelő helyiértéken van			
	MOV R3, A 					; elmentése az eremdény regiszterbe
	SJMP Helyiertek				; az alsó tárolás kihagyása
Also: 
	ADD A, R2 					; a felsővel azonos működés...
	MOV R2, A 					; a felsővel azonos működés...

; 4. Helyiérték választó (F0 flag) és tároló (R4 regiszter) aktualizálása

; A tároló regiszter értékének elforgatása 1-el balra, tehát a következőre léptetése
; túlcsordulás esetén az 1. helyiértékre ugrik vissza (carry nélkül forgatom)
Helyiertek:
	MOV A, R4 					; következő helyiértékre léptetés
	RL A	  					; forgatással
	MOV R4, A 					; tároljuk az aktuális értéket

; F0 beállítása (eredmény regiszter választó: alsó => F0 = 0, felső => F0 = 1)
; "túlcsordulás" (10...0 -> 0...01) esetén váltunk a felső eredmény tároló regiszterre, egyébként
; maradunk alapértelmezetten az alsón
	DEC A	  				    ; 0...01 - 0...01 = 0 , tehát ha Zero = 1, akkor MSB-ből LSB lett, tehát váltunk
	JNZ FelsoByteKezel			; egyébként az alapértelmezett alsó eredmény regiszter marad
	SETB F0   					; a felső eredmény regisztert választjuk ki
	
; 5. A "FELSŐ" érték kezelése
	
FelsoByteKezel:
	MOV A, R1 					; betöltjük "FELSŐ"-t az akkumulátorba						
	JZ AlsoFelezo	  			; amennyiben 0, nincs dolgunk vele (átlépjük a kezelését)

; Hasonló módon, mint az "ALSÓ"-nál, kiderítem, hogy páros vagy páratlan
; ennek alapján, ha páratlan, kivonok belőle egyet, ill. 
; egy regiszterbe elmentem, hogy a +50 decimális értéket hozzá kell adni,
; hiszen az itt 2-vel elosztott alsó helyiértéken lévő szám a 100-asok értéke
; ezt elosztva 2-vel +50-et kapunk és ennek az "ALSÓBA" történő átvitelére használom az R7 regisztert
	
	ANL A, #1 					; maszokolom a legalsó bitet, így ellenőrzöm, hogy páros vagy páratlan
								; Z flag jelzi, hogy:
								; páros -> Z = 0
								; páratlan -> Z = 1
	JZ FelsoParos				; a páratlan eset kezelésének kikerülése, ha páros a szám
	
FelsoParatlan:		
	DEC R1						; csökkentjük 1-el a "FELSŐ"-t (így osztható lesz 2-vel)
	MOV R7, #50					; R7-ben tárolom az átvitelt, ami 100/2 = 50 ("ALSÓ"hoz adom majd)
	SJMP FelsoFelezo			; Felső páros lekezelésének átugrása
FelsoParos:
	MOV R7, #0					; R7-ben tárolom az átvitelt, ami 0/ 2 = 0 	("ALSÓ"hoz adom majd)							
	

; 6. A decimális értékek aktualizálás (felezése)

; A módszernek megfelelően létrehozom a következő ciklushoz kellő értékeket
; ehhez felezem a decimális értékeket a megfelelő átvitelt biztosítva (FELSŐ -> ALSÓ)
FelsoFelezo:
	MOV A, R1					; R1-ben tárolt "FELSŐ" érték betöltése
	MOV B, #2					; segédregiszterrel osztás 2-vel
	DIV AB
	MOV R1, A					; visszatöltés
	
AlsoFelezo:
	MOV A, R0					; R0-ban tártot "ALSÓ" érték betöltése	
	MOV B, #2					; segédregiszterrel osztás 2-vel 
	DIV AB
	ADD A, R7					; a kapott értékhez hozzáadódik az átvitel (FELSŐ-ből)
	MOV R0, A					; visszatöltés
	MOV R7, #0					; az átvitel nullázása

	SJMP Ciklus					; előről kezdjük a ciklust
	
VegeHiba: 
	POP B						; a kezdeti értékek visszaállítása (fordított sorrendben)
	POP ACC
	POP 7
	POP 4
	POP 1
	POP 0
	POP PSW
	SETB F0						; a hiba jelzése F0 = 1-el
	MOV R2, #255				; hibás érték esetén 0xFFh az eredményregiszterek értéke
	MOV R3, #255
	
	
	RET							; visszatérés a hívóhoz
	
VegeNincsHiba: 
	POP B						; a kezdeti értékek visszaállítása (fordított sorrendben)
	POP ACC
	POP 7
	POP 4
	POP 1
	POP 0
	POP PSW
	CLR F0						; nem volt hiba jelzése F0 = 0-al
	
	RET							; visszatérés a hívóhoz
	
END	