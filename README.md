* [Motiváció](#motiváció)
* [A program funkciói](#a-program-funkciói)
* [A program használata](#a-program-használata)
* [Technikai megjegyzések](#technikai-megjegyzések)
* [Verziótörténet](#verziótörténet)

A program címe: http://research.physcon.uni-obuda.hu/RakregiszterVizualizator/.

# Motiváció

A magyar Nemzeti Rákregiszter (NRR) hazánk egyik legismertebb, legnagyobb hagyományú betegségregisztere. (Betegségregiszternek szokás nevezni azokat az adatbázisokat, mely valamely betegség vagy betegségcsoport (1) adott területi egységre, nagyon gyakran országra vonatkozóan az összes előfordulás begyűjtését célozza meg, a teljeskörűség igényével, (2) a megbetegedésre vonatkozóan kiterjedt klinikai adatokat is begyűjt, (3) gyakran utánkövetéses adatokat is tartalmaz, és végül (4) általában alapos, standardizált minőségbiztosítási módszereket alkalmaz az adatminőség garantálása érdekében.)

Az NRR hatalmas pozitívuma, összevetve más hazai betegségregiszterekkel, hogy az adatai meglehetősen transzparensek: a rákos megbetegedések esetszáma bárki számára, nyilvánosan lekérhetőek, sőt, életkor, nem, megye és pontos diagnózis szerint alá is bonthatóak. Szomorú ezt mondani, de magyar viszonylatban már ez is hatalmas fegyvertény (más hazai betegségregiszterek jó ha 5 számot közölnek nyilvánosan, de az se példátlan, hogy gyakorlatilag semmilyen érdemi adat nem érhető el publikusan), noha persze a nyugaton megszokottól még ez is odébb van. (Kezdve azzal, hogy kimeneti adatok vagy az előforduláson túli klinikai adatok, például stádiumra vonatkozó adatok még összesített formában sem érhetőek el; érdemes a hasonló célú amerikai intézet [honlapját](https://seer.cancer.gov/statistics/) megnézni.)

Az NRR-es adatoknak azonban egy hiányossága van, még ha csak az előfordulásra szorítkozunk is: a számokon kívül semmi mást nem kínál. Semmilyen elemzési, feldolgozási, vizualizálási, tehát általában, az orvosoknak - vagy akár érdeklődő laikusoknak - a felhasználást megkönnyítő funkcionalitása nincsen. Ez nem feltétlenül róható fel nekik: ők adatszolgáltatók, adatokat pedig tényleg szolgáltatnak. Akárhogy is, egy összekötő kapocs hiányzik: egyik oldalról megvannak az orvosilag releváns kérdések (mondjuk mennyi a kockázat adott rák fellépésére bizonyos életkorban), másik oldalról megvannak a nyers adatok, de a kettőt össze kell kötni, mert egy orvos vagy laikus egy tízezer sorból és húsz oszlopból álló számtáblából nem fog tud válaszolni erre a kérdésre. Ezt az összekötő kapocs szerepet próbáltam meg programommal betölteni. A cél az volt, hogy minél kényelmesebben használható, semmilyen programozási, statisztikai, adatfeldolgozási ismeretet nem igénylő módon lehessen a nyers adatok pontosan arra a formára hozni, mely a legjobban segíti az ilyen és ehhez hasonló kérdések megválaszolását.

A projektnek - legkevésbé sem titkolt - célja az is, hogy demonstrálja, mintegy esettanulmányként, hogy a felhasznált eszköztárral milyen erőteljes megoldást lehet adni az epidemiológiai vizsgálatok és általában a népegészségügy támogatására.

# A program funkciói

A program

# A program használata

A program felülete rendkívül intuitív: a tipikus lekérdezéseket a `Feladat` pont tartalmazza, az alapvető működést azt itt kiválasztott opció határozza meg. A választás függvényében a 

# Technikai megjegyzések

* Noha igyekeztem a lehető legalaposabban eljárni, a programhoz természetesen nincs garancia. Különösen most, hogy még a kezdeti fázisban van; pontosan emiatt viszont hálásan megköszönök minden tesztelést (kiemelten: ugyanazon elemzések, vizualizációk más módon történő elvégzését, és ezek eredményének összevetését az én programom által szolgáltatottakkal).
* Az előbbi cél érdekében a teljes munkám transzparens: ebben a GitHub repozitóriumban nyilvánosan elérhető tettem a teljes programot, mely alapján bárki reprodukálhatja az egész munkafolyamatot. Letölthető az [R szkript](app.R) és az [adatokat előkészítő szkript](RakregiszterScraper.R) (ez végzi az adatok - automatizált - letöltését az NRR honlapjáról, és annak, valamint az összes többi szükséges adatállománynak a feldolgozását) is. A teljes reprodukálthatóság kedvéért a letöltött állományok, valamint a felhasznált nyers adatok (standard korfák, térképek) szintén elérhetőek a repozitóriumban.
* A hibaellenőrzésektől teljesen függetlenül nagy örömmel veszek minden visszajelzést, javítási/bővítési ötletet.

# Verziótörténet

Verzió|Dátum|Kommentár
------|-----|---------
v2.00|2018-08-28|Kiinduló változat. (A 2.00-s verziószám ,,hagyománytiszteletből'' került rá, utalva a számos korábbi, változó fokban kiforrott változatra, melyek egy része már elérhető volt nyilvánosan is.)