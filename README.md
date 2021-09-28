* [Motiváció](#motiváció)
* [A program funkciói](#a-program-funkciói)
* [A program használata](#a-program-használata)
* [Megjegyzések](#megjegyzések)
* [Verziótörténet](#verziótörténet)

A program címe: http://research.physcon.uni-obuda.hu/RakregiszterVizualizator/.

# Motiváció

A magyar [Nemzeti Rákregiszter](http://www.onkol.hu/hu/nemzeti_rakregiszter) (NRR) hazánk egyik legismertebb, legnagyobb hagyományú betegségregisztere. (Betegségregiszternek szokás nevezni azokat az adatbázisokat, mely valamely betegség vagy betegségcsoport (1) adott területi egységre, nagyon gyakran országra vonatkozóan az összes előfordulás begyűjtését célozza meg, a teljeskörűség igényével, (2) a megbetegedésre vonatkozóan kiterjedt klinikai adatokat is begyűjt, (3) gyakran utánkövetéses adatokat is tartalmaz, és végül (4) általában alapos, standardizált minőségbiztosítási módszereket alkalmaz az adatminőség garantálása érdekében.)

Az NRR hatalmas pozitívuma, összevetve más hazai betegségregiszterekkel, hogy az adatai meglehetősen transzparensek: a rákos megbetegedések esetszámai bárki számára, nyilvánosan lekérhetőek, sőt, diagnózis éve, életkor, nem, megye és pontos diagnózis szerint alá is bonthatóak. Szomorú ezt mondani, de magyar viszonylatban már ez is hatalmas fegyvertény (más hazai betegségregiszterek jó ha 5 számot közölnek nyilvánosan a nyers adatokból, de az se példátlan, hogy gyakorlatilag semmilyen érdemi adat nem érhető el publikusan), noha persze a nyugaton megszokottól még ez is odébb van. (Kezdve azzal, hogy kimeneti adatok vagy az előforduláson túli klinikai adatok, például stádiumra vonatkozó adatok még összesített formában sem érhetőek el; érdemes a hasonló célú amerikai intézet [honlapját](https://seer.cancer.gov/statistics/) megnézni.)

Az NRR-nek azonban egy hiányossága van, még ha csak az előfordulási adatokra szorítkozunk is: a számokon kívül semmi mást nem kínál. Semmilyen elemzési, feldolgozási, vizualizálási, tehát általában, az orvosoknak - vagy akár érdeklődő laikusoknak - a felhasználást, konkrét kérdések megválaszolását megkönnyítő funkcionalitása nincsen. Ez nem feltétlenül róható fel nekik: ők adatszolgáltatók, adatokat pedig tényleg szolgáltatnak. Akárhogy is, egy összekötő kapocs hiányzik: egyik oldalról megvannak az orvosilag releváns kérdések (mondjuk mennyi a kockázat adott rák fellépésére bizonyos életkorban), másik oldalról megvannak a nyers adatok, de a kettőt össze kell kötni, mert egy orvos vagy laikus egy tízezer sorból és húsz oszlopból álló számtáblából nem fog tud válaszolni erre a kérdésre. Ezt az összekötő kapocs szerepet próbáltam meg programommal betölteni. A cél az volt, hogy minél kényelmesebben használható, semmilyen programozási, statisztikai, adatfeldolgozási ismeretet nem igénylő módon lehessen a nyers adatokat pontosan arra a formára hozni, mely a legjobban segíti az ilyen és ehhez hasonló kérdések megválaszolását - legyen szó laikus érdeklőtől tudományos kutatásig bármilyen felhasználásról.

A projektnek - legkevésbé sem titkolt - célja az is, hogy demonstrálja, mintegy esettanulmányként, hogy a felhasznált eszköztárral (`R`, `shiny`, `lattice`, `data.table`) milyen erőteljes megoldást lehet adni az epidemiológiai vizsgálatok és általában a népegészségügy támogatására.

# A program funkciói

A megbetegedések esetszámai, az, hogy 10 vastagbélrákos eset fordult elő, önmagában nem sokat jelent. (Ne feledjük, az NRR-ben ez szerepel!) Viszonyítani kell őket, minimum két szempont alapján: mennyi emberből (még pontosabban: a megbetegedés kockázatának kitett emberből) és mennyi idő alatt történt ennyi eset. Nagyon nem mindegy, hogy 100-ból betegedtek meg 10-en vagy 100 ezerből, és nem mindegy, hogy 1 hónap alatt vagy 10 év alatt.

## Az incidencia fogalma

Az ezt megragadó fogalom az *incidencia*: kifejezi, hogy egységnyi idő (tipikusan 1 év) alatt, egységnyi kockázatnak kitett ember (tipikusan 100 ezer fő) körében hány új megbetegedés lép fel. Bármiféle további számításnak tehát csak az incidencia használatával van értelme.

Ahhoz, hogy incidenciát tudjunk számolni, szükségünk van tehát egyfelől arra, hogy az adatokat évekre bontsuk (ezt az NRR is megteszi), másfelől, hogy adott év adott diagnózisának esetszámához hozzá tudjuk társítani a "kockázatnak kitett populációt". Ez legegyszerűbb esetben az egész népesség, azaz az esetek számát egyszerűen a lakosságszámmal kell leosztanunk, de az információforrás részletgazdagságának fényében lehetünk finomabbak is. Például az NRR megadja a betegek nemét is, így megtehetjük, hogy az adott évben adott diagnózisból előforduló betegek közül megnézzük, hogy hány volt férfi, és az ő számukat (nem az összes betegét) az ország azévi férfilakosságának (nem az összlakosságának) a számára osztjuk rá, és hasonlóan a nőbetegek számát a női lakosok számával osztjuk. (Így két incidenciát kapunk, ezeket szokás nemspecifikus incidenciának nevezni.) Megtehetjük ugyanezt életkor szerint is: hogy a 0-4 év közötti esetszámot a 0-4 év közötti gyerekek számával osztjuk, ez a korspecifikus incidencia. (Természetesen a kettő kombinálható is.) Az NRR adatai még egy lebontást tesznek lehetővé, a megyénkéntit. Mindezekhez persze az kell, hogy tudjuk a megfelelő népességszámokat, természetesen nem csak összességében, hanem - mint az előző példák mutatják - minden egyes rétegben is, tehát ismerjük évenként, nemenként, korcsoportonként és megyénként a lakosságszámokat, szerencsére ezek a korfák elérhetőek a KSH-nál.

## A standardizálás

Még egy dologra kell figyelni, ha hosszú időtávokat hasonlítunk össze, vagy ha a magyar adatokat más országok adataival akarjuk összevetni: mivel a populációk összetétele - időben vagy térben - eltérhet, így az incidenciák egyszerű összehasonlítása nagyon félrevezető lehet. Mi az, hogy "eltér a populáció összetétele"? Vegyük a legegyszerűbb példát, az életkort. Ha nem korspecifikus incidenciát használunk, akkor nagyon furcsa dolgok történhetnek olyan esetekben, amikor az életkor hat a betegség kockázatára (nagyon sok rákos megbetegedés erősen ilyen, a legtöbbnél a kockázat az életkor emelkedésével nő). Például azt fogjuk látni, hogy Szváziföldön nagyon alacsony az incidencia, Svájcban jóval magasabb. Akkor tehát a szváziföldi egészségügyi helyzet ennyivel jobb mint a svájci?! Dehogy, egész egyszerűen arról van szól, hogy Szváziföldön a HIV/AIDS járvány azelőtt elviszi az ottaniak egy jó részétm, mielőtt egyáltalán megérnék azt az életkort, ahol már nagy lesz a rákkockázat! (A 2000-es évek elején a születéskor várható élettartam 45 év alá esett Szváziföldön, 10%-os csecsemőhalandósággal.) Szó nincs tehát arról, hogy ott ennyivel jobb a helyzet, egyszerűen annyira eltér a két ország korfája, hogy egy - életkortól függő kockázatú - betegség előfordulása gyakorlatilag összehasonlíthatatlan. Az ilyen mutatót, ami nincs tekintettel ezekre az eltérésekre, általában is *nyers* mutatónak szokás nevezni, jelen esetben tehát *nyers incidenciáról* beszélhetünk. A probléma természetesen nem csak különböző országok viszonyában jelentkezhet egymás között, hanem ugyanazon országon belül is, ha olyan távoli időpontokat hasonlítunk össze, melyek között már lényegesen megváltozott a korfa. (Vélhetően nem követünk el nagy hibát, ha a tavalyi és az idei nyers incidenciákat összehasonlítjuk Magyarországon, de a 2001-es és a 2015-ös nyers incidenciák már egyáltalán nem biztos, hogy összevethetőek, hiába vagyunk egy országon belül, annyira jelentős a lakosság idősödése.)

Mi lehet e probléma megoldása? Mit tehet mégis a helyes összehasonlítás érdekében?

Az első lehetőség kézenfekvő: ne a nyers incidenciákat nézzük, hanem a korspecifikus incidenciákat. Minden korcsoportot külön-külön összevetve azonnal világos lesz, hogy a szváziföldi helyzet sokkal rosszabb (vélhetően minden korcsoportban). Ez a módszer a problémát tökéletesen megoldja, más gond van vele: az, hogy kényelmetlen. Nem két számot kell összevetnünk, hanem 18-at (ha 5 éves korcsoportokat használunk, mint az NRR). A helyzet tovább romlik, ha netán az eltérő nemi összetétel miatt is aggódunk, hiszen ekkor már 36 rétegünk lesz.

Éppen ezért alakult ki, több mint 150 évvel ezelőtt, egy másik megoldás, melyet *direkt standardizálásnak* szokás nevezni. Ennek lényege, hogy elvégezzük a rétegekre lebontást, tehát kiszámoljuk a korspecifikus incidenciákat, de utána nem a rétegekhez tartozó lakosságszámokkal súlyozva rakjuk őket újra egybe (így kapnánk a nyers incidenciát), hanem a tényleges korfától függetlenül mindig ugyanazt a - standard - korfát használjuk, így szabadulva meg az eltérő korfák problémájától. Az így kapott incidencia természetesen már nem szokásos incidencia, hiszen nem összetartozó korfát és korspecifikus incidenciákat használtunk, de összehasonlításra alkalmas; ezt szokás *standardizált incidenciának* nevezni.

Végezetül egy harmadik, korszerű lehetőség a regressziós modellezéssel történő korrigálás; a program ezt is támogatja. A regressziós modellezés nagyon sok szempontból jobb, mint a hagyományos epidemiológiai standardizálás (flexibilisebb, a feltevések ellenőrizhetőek benne stb.), de a mindennapi gyakorlatban még kevésbé terjedt el.

# A program használata

A program felülete rendkívül intuitív: a tipikus lekérdezéseket a `Feladat` pont tartalmazza, az alapvető működést azt itt kiválasztott opció határozza meg. A program a következő lehetőségeket támogatja:
* Kor- és/vagy nemspecifikus incidencia: ábrázolható a korspecifikus, a nemspecifikus valamint a kor- és nemspecifikus incidencia minden diagnózisra. Ábrázolható adott évre vagy az összes évre, adott megyére vagy az összes megyére (ezek kombinálhatóak is) egy ábrán, valamint minden egyes évre külön-külön ábrán (ez végrehajtható az összes megyére, vagy egy megyére szűkítve), és minden egyes megyére külön-külön ábrán (ez végrehajtható az összes évre, vagy egy évre szűkítve).
* Kor- és/vagy nemspecifikus incidencia alakulása az időben: ábrázolható a korspecifikus, a nemspecifikus valamint a kor- és nemspecifikus incidencia időbeli (évenkénti) alakulása egy adott diagnózisra.
* Nyers incidencia alakulása időben: ábrázolható egy adott diagnózisra a nyers incidencia alakulása időben.
* Standardizált incidencia alakulása időben: ábrázolható egy adott diagnózisra a standardizált incidencia alakulása időben. A használt standard populáció kiválasztható.
* Megyénkénti nyers incidenciák: színezett térképen ábrázolhatóak a megyénkénti nyers incidenciák adott diagnózisra, az összes évre vagy egy adott évre.
* Megyénkénti standardizált incidenciák: színezett térképen ábrázolhatóak a megyénkénti standardizált incidenciák adott diagnózisra, az összes évre vagy egy adott évre. A használt standard populáció kiválasztható.

A kevésbé alapvető beállítási lehetőségek alapértelmezetten rejtve vannak, a `Haladó beállítások megjelenítése` opciót bepipálva jeleníthetőek meg. Ezek a következők:
* A kapott eredmények - a térképes ábrázolásokon kívül - elláthatóak konfidenciaintervallummal. (Ezt bekapcsolva megadható a megbízhatósági szint és a stílus: sávokkal vagy besatírozott területtel jelenjen meg a konfidenciaintervallum.)
* A függőleges tengely skálázása - a térképeken kívül - logaritmikussá tehető.
* A függőleges tengely (nem térképeknél) illetve a színtengely (térképeknél) minimuma és maximuma kézzel is beállítható. (Ha nincs ez az opció bepipálva, akkor a program automatikusan határozza meg ezeket az értékeket, optimálisan megválasztva őket az adatok alapján. Ezen lehetőség használata például akkor lehet célszerű, ha több ábrán fontos, hogy ugyanaz legyen a tengely skálázása.)
* Az exportált PNG fájl szélessége és magasság megadható (pixelben).

Ezek a funkciók érhetőek el az - alapértelmezett - 'Vizualizáció' üzemmódban. A program átkapcsolható a legfelső gombbal 'Modellezés' üzemmódba, ekkor kiválasztható az egyes tényezők függvényformája; ez esetben az így kapott modell vizualizációja jelenik meg jobb oldalon.

# Megjegyzések

* Noha igyekeztem a lehető legalaposabban eljárni, a programhoz természetesen nincs garancia. Különösen most, hogy még a kezdeti fázisban van; pontosan emiatt viszont hálásan megköszönök minden tesztelést (kiemelten: ugyanazon elemzések, vizualizációk más módon történő elvégzését, és ezek eredményének összevetését az én programom által szolgáltatottakkal).
* Az előbbi cél érdekében a teljes munkám transzparens: ebben a GitHub repozitóriumban nyilvánosan elérhető tettem a teljes programot, mely alapján bárki reprodukálhatja az egész munkafolyamatot. Letölthető az [R szkript](app.R) és az [adatokat előkészítő szkript](RakregiszterScraper.R) (ez végzi az adatok - automatizált - letöltését az NRR honlapjáról, és annak, valamint az összes többi szükséges adatállománynak a feldolgozását) is. A teljes reprodukálthatóság kedvéért a letöltött állományok, valamint a felhasznált nyers adatok (standard korfák, térképek) szintén elérhetőek a repozitóriumban.
* A hibaellenőrzésektől teljesen függetlenül is nagy örömmel veszek minden visszajelzést, javítási/bővítési/továbbfejlesztési ötletet!
* (Disclaimer: ez egy hobbi-projekt a részemről, nincsen semmilyen finanszírozása, nincsenek orvosi együttműködő partnereim vagy támogatóim, teljesen magamtól, a saját gondolataim alapján fejlesztettem a szabadidőmben.)

## Módszertani megjegyzések

* Az NRR-ben fellelhető "Megyén kívüli" jelzésű megyéjű alanyokat a program eldobja. (Így ugyan keletkezik némi veszteség, hiszen például életkori vagy nemi elemzésekhez ezek felhasználhatóak lennének, de ez egyrészt egészen minimális - 0,1% körüli - másrészt így minden eredmény konzisztens, olyan értelemben, hogy ugyanazon alanyok alapján készült.)
* A standard populációkat [külön fájl](StdPops18.csv) tárolja, ezek - a hozzájuk tartozó irodalmi hivatkozásokkal - a következőek:

  + Segi-Doll (1960): Segi, M. (1960) Cancer Mortality for Selected Sites in 24 Countries (1950–57). Department of Public Health, Tohoku University of Medicine, Sendai, Japan. Doll, R., Payne, P., Waterhouse, J.A.H. eds (1966). Cancer Incidence in Five Continents, Vol. I. Union Internationale Contre le Cancer, Geneva.
  + ESP (2013): Pace, M., Lanzieri, G., Glickman, M. et al (2013). Revision of the European Standard Population: report of Eurostat's task force. Publications Office of the European Union. [Link](https://ec.europa.eu/eurostat/documents/3859598/5926869/KS-RA-13-028-EN.PDF/e713fa79-1add-44e8-b23d-5e8fa09b3f8f).
  + WHO (2001): Ahmad, O. B., Boschi-Pinto, C., Lopez, A. D., Murray, C. J., Lozano, R., Inoue, M. (2001). Age standardization of rates: a new WHO standard. Geneva: World Health Organization. [Link](http://www.who.int/healthinfo/paper31.pdf).
  + Magyar (2001-2015): Ezt a program belsőleg számolja, nem más, mint a beolvasott korfa valamennyi évre aggregált adata, természetesen nem és életkor szerint lebontva.
  
* A megyei felbontású térképek forrása az OpenStreetMap ([link](https://data2.openstreetmap.hu/hatarok/)).
* A konfidenciaintervallumok Clopper-Pearson (egzakt) eljárással számolódnak.
* A modellezés Poisson-regresszió, offszet a megfelelő réteg lakosságszámának logaritmusa, a modell pedig a felhasználó által beállított választásokból összerakott modell (azzal, hogy az életkor és a nem között mindenképp van interakció, de minden más additív).

## Technikai megjegyzések

* A program `R` statisztikai környezet alatt fut, az adatbázis kezelésére `data.table` könyvtárat használ, a webes felület létrehozása és kezelése pedig `shiny` segítségével valósul meg.
* A vizualizáció a grafikonok esetében `lattice`-szal (illetve az azon alapuló `Hmisc`-kel) történik, a térképek esetében az `sp` csomaggal.
* A program automatikusan scrape-eli le az NRR adatbázisát a `httr` és az `rvest` könyvtárak használatával, évenkénti bontásban, majd az eredményeket [egy fájlba](RawDataWide.csv) fűzi, és végül [long formátumra](RawDataLong.csv.gz) alakítja.
* A háttérpopuláció lélekszámai a [KSH tájékoztatási adatbázis](https://statinfo.ksh.hu/Statinfo/themeSelector.jsp?lang=hu) NT1C02 és NT2C02 jelű tábláiból származnak (minden évre az évközepi lélekszámot használva, a területi egységhez nem rendelhető számokat eldobva). A long formátumú adatokat a melléjük illesztett háttérpopulációs létszámokkal ismét [külön fájlban](RawDataLongWPop.csv.gz) tárolja.
* A direkt standardizáció elvégzéséhez a program az `epitools` csomagot használja.
* A flexibilis modellezés az `rms` csomag segítségével történik.

# Verziótörténet

Verzió|Dátum|Kommentár
------|-----|---------
v2.00|2018-08-28|Kiinduló változat. (A 2.00-s verziószám "hagyománytiszteletből" került rá, utalva a számos korábbi, változó fokban kiforrott változatra, melyek egy része már elérhető volt nyilvánosan is.)
v2.10|2018-10-11|<ul><li>Az exportált PNG fájl méretei beállíthatóak lettek.</li><li>Az ábráknál a függőleges tengely/színtengely kézzel is skálázható lett (tehát a minimuma és a maximuma kézzel is megadható).</li><li>Az ábráknál (a térképek kivételével) a függőleges tengely mindenhol logaritmikussá tehető.</li><li>Az ábrák címei egységesek és logikusabbak lettek (a cím alatti sorban zárójelben jelennek meg a paraméterek).</li><li>Konfidenciaintervallum mindenre rakható lett a térképek kivételével.</li><li>A haladó beállítások csoportosítva, külön, egy alapértelmezetten nem megjelenő (külön gombbal megjeleníthető) panelre kerültek.</li></ul>
v2.11|2019-06-25|Hibajavítás: az exportált PNG-kép nem volt jó.
v2.12|2019-10-18|Hibajavítás: a modellezés üzemmódban a megyét nem lehetett nem-paraméteresre állítani.
v2.20|2020-03-09|<ul><li>A 'Kor- és/vagy nemspecifikus incidencia alakulása időben' pont is lebontható megyék szerint, illetve kiválaszható egyetlen megye.</li><li>A 'Nyers incidencia alakulása időben' és a 'Standardizált incidencia alakulása időben' pont is lebontható megyék szerint, illetve kiválaszható egyetlen megye.</li><li>A 'Standardizált incidencia alakulása időben' pont elegánsabban írja ki a standard nevét az ábra fejlécében.</li></ul>
v2.21|2021-09-28|Frissítés az NRR aktuális adataira (2000-2018 elérhető) és a scraper frissítése az NRR aktuális adatszolgáltatási formátumára.