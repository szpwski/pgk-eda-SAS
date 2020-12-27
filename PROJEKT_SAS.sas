/* PROJEKT SAS NA ZAJECIA PROGRAMOWANIA SAS */
/* Projekt polega na przeanalizowaniu danych podatkowych grup kapitałowych z 2016,2017 i 2018 roku */
/* Analizowane będą głównie dane grup występujących częściej niż raz na zeznaniach */
/* Autor: Szymon Pawłowski */

%LET path="your_path";

/* Tworzymy biblioteke */
libname projekt "your_lib_path";

%macro import(rok);
	%if (&rok NE 2016 and &rok NE 2017 and &rok NE 2018) %then
		%do;
			%PUT "DOZWOLONE ARGUMENTY TO: 2016, 2017, 2018 !!!";
		%end;
	%else %if &rok=2018 %then
		%do;
			%* Plik xlsx aby importować nazwy podatników z polskimi znakami;

			proc import datafile="your_file_path" 
					out=projekt.pgk_&rok dbms=xlsx replace;
				getnames=no;
				datarow=11;
			run;

			%* Badamy zaimportowane zbiory;
			ods proclabel "Wstępne zbadanie zbioru PGK &rok";
			title "Wstępne zbadanie zbioru PGK &rok";

			proc contents data=projekt.pgk_&rok;
				title "Wstępne zbadanie zbioru PGK_&rok.xlsx";
			run;

			%* Liczba zmiennych jest zgodna z plikiem źródłowym;
			%* Formaty zmiennych są prawidłowe;
			%* Wyswietlimy pierwsze i ostatnie 10 obserwacji;
			title "Pierwsze i ostatnie 10 obserwacji z &rok";

			data first10_last10 /view=first10_last10;
				do nobs=1 by 1 until(eof);
					set projekt.pgk_&rok(drop=_all_) end=eof;
				end;

				do _n_=1 to nobs;
					set projekt.pgk_&rok;

					if _n_ <=10 or _n_ >=nobs - 9 then
						output;
				end;
			run;

			title "Wyświetlenie pierwszych i ostatnich 10 obserwacji z &rok";

			proc print data=first10_last10;
				%* Mozna zauwazyc braki danych i zera;
				%* Sprawdzmy ilosc braków danych;
				ods proclabel "Sprawdzenie ilości braków danych z &rok";

			proc means data=projekt.pgk_&rok n nmiss;
				ods proclabel "Sprawdzenie ilości braków danych z &rok";
				title "Badanie ilości braków danych względem wszystkich obserwacji z &rok";
			run;

			%* Po wstępnym zbadaniu importowanego zbioru musimy przeprowadzić 
				następujące czynności: */ /* 1. Zmienić nazwy zmiennych na te ze zbioru */

				/* 2. Braki danych zamienić na zera (tablica będzie bardziej przejrzysta) w zmiennych G-Q;
				data projekt.pgk_&rok;
				set projekt.pgk_&rok;
				array change _numeric_;
				
				do over change;
				
				if change=. then
				change=0;
				end;
				rename A=LP B=PODATNIK C=NIP D=POCZATEK_OKRESU E=KONIEC_OKRESU F=PRZYCHODY
				G=PRZYCHODY_KAPITAL H=PRZYCHODY_INNE I=KOSZTY_PRZYCHODU J=KOSZTY_KAPITAL
				K=KOSZTY_INNE L=DOCHOD M=DOCHOD_KAPITAL N=DOCHOD_INNE O=STRATA
				P=STRATA_KAPITAL Q=STRATA_INNE R=PODSTAWA_OPODATKOWANIA S=PODATEK_NALEZNY;
				run;
				ods proclabel "Ponowne sprawdzenie braków danych z &rok";
				proc means data=projekt.pgk_&rok n nmiss;
				title "Sprawdzenie ilości braków danych względem wszystkich obserwacji z &rok";
				run;
				%end;
				%* Zbiór jest gotowy do analizy;
				%else %do;
				%*Musimy w inny sposób zaimportować kolejne zbiory ponieważ po wcześniejszym obejrzeniu
				ich możemy dostrzec, że różnią się ilością kolumn bądź też rekordów
				Dlatego stosujemy tutaj instrukcje warunkowe;
				%if &rok=2017 %then %do;
				
				proc import datafile="your_file_path"
				out=projekt.pgk_2017 dbms=xlsx replace;
				range="2017_stan_na_01_03_20$A10:K79";
				getnames=no;
				run;
				%end;
				%else %do;
				proc import datafile="your_file_path"
				out=projekt.pgk_2016 dbms=xlsx replace;
				range="2016_stan_na_01_03_20$A10:K68";
				getnames=no;
				run;
				%end;
				ods proclabel "Wstępne zbadanie zbioru PGK &rok";
				proc contents data=projekt.pgk_&rok;
				title "Wstępne zbadanie zbioru PGK_&rok.xlsx";
				run;
				title "Pierwsze i ostatnie 10 obserwacji z &rok";
				data first10_last10 /view=first10_last10;
				do nobs=1 by 1 until(eof);
				set projekt.pgk_&rok(drop=_all_) end=eof;
				end;
				
				do _n_=1 to nobs;
				set projekt.pgk_&rok;
				
				if _n_ <=10 or _n_ >=nobs - 9 then
				output;
				end;
				run;
				ods proclabel "Wyświetlenie pierwszych i ostatnich 10 obserwacji z &rok";
				proc print data=first10_last10;
				proc means data=projekt.pgk_&rok n nmiss;
				ods proclabel "Sprawdzenie ilości braków danych z &rok";
				title "Badanie ilości braków danych względem wszystkich obserwacji z &rok";
				run;
				
				data projekt.pgk_&rok;
				set projekt.pgk_&rok;
				array change _numeric_;
				
				do over change;
				
				if change=. then
				change=0;
				end;
				rename A=LP B=PODATNIK C=NIP D=POCZATEK_OKRESU E=KONIEC_OKRESU F=PRZYCHODY
				G=KOSZTY_PRZYCHODU H=DOCHOD I=STRATA J=PODSTAWA_OPODATKOWANIA
				K=PODATEK_NALEZNY;
				run;
				ods proclabel "Ponowne badanie ilości braków danych z &rok";
				proc means data=projekt.pgk_&rok n nmiss;
				title "Sprawdzenie ilości braków danych względem wszystkich obserwacji z &rok";
				run;
				%end;
				%*Zbior jest gotowy do analizy;
				%mend;
				
				/* Zbiory zostały zaimportowane i przygotowane do analizy */
				/* Sprawdźmy, ile razy grupy kapitałowe składały zeznanie podatkowe */
				/* Im częściej tym pewniejszy podatnik */
				%macro czestosc;
				%*Sortujemy zbiory, aby połączyć je w jeden zbiór danych, dzięki temu 
					dowiemy się o częstości;
				ods proclabel "Najczęściej występowane grupy kapitałowe";

				proc sort data=projekt.pgk_2018;
					by podatnik;
				run;

				proc sort data=projekt.pgk_2017;
					by podatnik;
				run;

				proc sort data=projekt.pgk_2016;
					by podatnik;
				run;

				data projekt.spolki;
					set projekt.pgk_2018 projekt.pgk_2017 projekt.pgk_2016;
					by podatnik;
				run;

				%*Wyświetlimy teraz częstość występowania spółek w zeznaniach podatkowych;

				proc freq data=projekt.spolki;
					tables podatnik /out=projekt.spolki_freq(where=(count>1)) nocum nopercent;
					title "Częstość występowania spółek w zeznaniach podatkowych";
				run;

				proc freq data=projekt.spolki;
					tables podatnik /out=projekt.spolki_freqall(where=(count<=3)) noprint nocum 
						nopercent;
					title "Częstość występowania spółek w zeznaniach podatkowych";
				run;

				*&Zbadamy dodatkowo strukturę występowania dla wszystkich grup kapitałowych;

				proc sgplot data=projekt.spolki_freqall;
					title "Struktura występowania grup kapitałowych";
					ods proclabel "Struktura występowania grup kapitałowych";
					histogram count;
				run;

			%mend;

			%*Dodatkowo stworzymy nowy zbior dla spółek które występują częściej niż raz;

			%macro czeste_spolki;
				%*Pozbywamy się błędu wynikającego z braku pełnej nazwy, aby otrzymać 
					wiarygodne wyniki odnośnie częstości;

				data projekt.czeste_spolki;
					merge projekt.spolki_freq(in=nipf) projekt.spolki (in=nips);

					if nipf;
					by podatnik;
					drop percent;

					if Count>3 then
						delete;
					rename Count=CZESTOSC;
				run;

				%*Sortujemy, aby pozbyć się duplikatów;

				proc sort data=projekt.czeste_spolki(keep=podatnik nip czestosc 
						podatek_nalezny) out=projekt.czeste_spolki_info nodupkey;
					by nip;
				run;

				proc print data=projekt.czeste_spolki_info;
					title 'Najczęstsze spółki';
					ods proclabel 'Spis najczęściej występowanych grup kapitałowych';
				run;

				%*Zobrazujemy sobie jakie ilości występowania dominują;

				proc sgplot data=projekt.czeste_spolki_info;
					title 'Badanie dominującej ilości występowania';
					ods proclabel 'Badanie dominującej ilości występowania';
					vbar czestosc;
				run;

			%mend;

			%macro histogramy;
				%*Stworzymy histogram ukazujący rozkład wysokości podatku należnego 
					zależnie od występowania spółek;

				proc sgplot data=projekt.czeste_spolki_info;
					ods proclabel 
						"Rozłożenie wysokości kwot podatku dochodowego w zależności od częstości";
					histogram podatek_nalezny / group=czestosc;
				run;

				%* Stworzymy histogram, aby móc ukazać w jaki % danych kwot zajmują 
					przychody, dochody, a jakie straty;
				ods proclabel "Przychody, dochody i straty - histogram";

				proc sgplot data=projekt.czeste_spolki noautolegend;
					title 
						"Udział przychodów, dochodów i strat w danych przedziałach kwotowych";
					histogram przychody /name='p' legendlabel='Przychod';
					histogram dochod /name='d' legendlabel='Dochod';
					histogram strata /name='s' legendlabel='Strata';
					keylegend 'p' 'd' 's' / location=inside position=topright across=1 
						noborder;
					yaxis offsetmin=0;
					xaxis display=(nolabel);
				run;

			%mend;

			%* Tworzymy makro, dzięki któremu poznamy 3 spółki o najwyższych oraz 
				najniższych przychodach/dochodach/stratach zależnie od parametru, na którym 
				nam zależy w konkretnych latach.
Zaprezentujemy dodatkowo te dane na wykresach;

			%macro lowandtop(zmienna, k);
				%*Tworzymy oddzielny zbiór dla każdego roku;

				%if (&zmienna ne przychody and &zmienna ne dochod and &zmienna ne strata 
					and &k ne 2016 and &k ne 2017 and &k ne 2018) %then
						%do;
						%PUT "DOZWOLONE ARGUMENTY DLA ZMIENNA: PRZYCHODY, DOCHOD, STRATA!!!";
						%PUT "DOZWOLONE ARGUMENTY DLA K: 2016, 2017, 2018!!!";
					%end;
				%else
					%do;

						proc sort data=projekt.czeste_spolki(where=(year(koniec_okresu)=&k)) 
								out=po_&zmienna&k;
							by &zmienna;
						run;

						data first3_&k /view=first3_&k;
							%*Wczytujemy pierwsze 3 (najmniejsze) i ostatnie 3 (najwieksze);

							do nobs=1 by 1 until(eof);
								set po_&zmienna&k (drop=_all_) end=eof;
							end;

							do _n_=1 to nobs;
								set po_&zmienna&k;

								if _n_<=3 then
									output;
							end;
						run;

						data last3_&k /view=last3_&k;
							do nobs=1 by 1 until(eof);
								set po_&zmienna&k (drop=_all_) end=eof;
							end;

							do _n_=1 to nobs;
								set po_&zmienna&k;

								if _n_ >=nobs - 2 then
									output;
							end;
						run;

						%*Tworzymy zbiory oddzielnie dla największych kwot i oddzielnie dla 
							najmniejszych;

						data projekt.top3_&zmienna&k;
							set first3_&k(keep=podatnik &zmienna);
						run;

						data projekt.last3_&zmienna&k;
							set last3_&k(keep=podatnik &zmienna);
						run;

						proc print data=projekt.top3_&zmienna&k;
							ods proclabel "Zbiór 3 spółek o największych: &zmienna w roku: &k";
							%*Przedstawimy różnice na wykresie;
							title "Minimalne 3 spółki względem: &zmienna w roku: &k";

						proc sgplot data=projekt.top3_&zmienna&k;
							ods proclabel 
								"Przedstawienie 3 spółek o największych: &zmienna w roku: &k";
							scatter x=podatnik y=&zmienna / filledoutlinedmarkers 
								markerfillattrs=(color=red) markeroutlineattrs=(color=red thickness=2) 
								markerattrs=(symbol=circlefilled size=25);
						run;

						proc print data=projekt.last3_&zmienna&k;
							ods proclabel "Zbiór 3 spółek o najniższych: &zmienna w roku: &k";
							title "Maksymalne 3 spółki względem: &zmienna w roku: &k";

						proc sgplot data=projekt.last3_&zmienna&k;
							ods proclabel 
								"Przedstawienie 3 spółek o najniższych: &zmienna w roku: &k";
							scatter x=podatnik y=&zmienna / filledoutlinedmarkers 
								markerfillattrs=(color=green) markeroutlineattrs=(color=green 
								thickness=2) markerattrs=(symbol=circlefilled size=25);
						run;

					%end;
			%mend;

			%*Stworzymy makro, które będzie generowało zbiór zawierający dane 
				wyliczone (min, max, średnia, odchylenie) dla poszczególnych czynników w 
				poszczególnych latach względem wszystkich spółek;

			%macro dane_wyliczone;
				ods proclabel "Dane wyliczone dla poszczególnych czynników";

				%do k=2016 %to 2018;

					data projekt.podatnik_&k;
						%*Będziemy tworzyć nowe rekordy dla poszczególnych lat;
						set projekt.czeste_spolki(where=(year(poczatek_okresu)=&k) keep=podatnik 
							poczatek_okresu przychody dochod strata);
						Przychody_&k=przychody;
						Dochod_&k=dochod;
						Strata_&k=strata;
						drop poczatek_okresu przychody dochod strata;
						format przychody_&k dochod_&k strata_&k comma15.;
					run;

					proc sort data=projekt.podatnik_&k;
						by podatnik;
					run;

				%end;
				%* Dzięki temu po połączeniu tabeli, będziemy mogli łatwiej otrzymać 
					kolumny wyliczone;

				data projekt.podatnicy_lata;
					merge projekt.podatnik_2016 projekt.podatnik_2017 projekt.podatnik_2018;
					by podatnik;
				run;

				proc means data=projekt.podatnicy_lata sum mean var std noprint;
					output out=projekt.srednie_dane;
				run;

				%* Przetransponujemy zbiór, aby dane były czytelniejsze i łatwiej można 
					było je odnaleźć;

				proc transpose data=projekt.srednie_dane(drop=_TYPE_ _FREQ_) 
						out=projekt.srednie_dane_t (drop=COL1 rename=(_NAME_=NAZWA COL2=MIN COL3=MAX 
						COL4=MEAN COL5=STD));
				run;

				proc print data=projekt.srednie_dane_t;
					title "Dane szczegółowe odnośnie poszczególnych czynników w danych latach dla wszystkich spółek";
				run;

			%mend;

			%*Tworzymy makro, które przedstawi nam na wykresie liniowym zmiany roczne 
				danej zmiennej na przestrzeni lat 2016-2018;

			%macro zmiana(zmienna);
				%if (&zmienna ne przychody and &zmienna ne dochod and &zmienna ne strata) 
					%then
						%do;
						%PUT "DOZWOLONE ARGUMENTY TO: PRZYCHODY, DOCHOD, STRATA!!!";
					%end;
				%else
					%do;

						data projekt.zmiana_&zmienna;
							set projekt.srednie_dane_t(where=(NAZWA like propcase("&zmienna%")));
							rok=_N_+2015;
						run;

						%*Tworzymy oddzielne serie na jednym wykresie;

						proc sgplot data=projekt.zmiana_&zmienna;
							ods proclabel "Przedstawienie zmiany: &zmienna w latach 2016-2018";
							series x=rok y=min /name='min' legendlabel="Minimum";
							series x=rok y=max /name='max' legendlabel="Maksimum";
							series x=rok y=mean /name='mean' legendlabel="Średnia";
							series x=rok y=std /name='std' legendlabel="Odchylenie";
							keylegend 'min' 'max' 'mean' 'std' / location=inside position=right 
								across=1 noborder;
							yaxis label='Wartość';
						run;

					%end;
			%mend;

			ODS HTML PATH="&path" (url=none) BODY='body.html' CONTENTS='toc.html' 
				style=raven;
			ODS TEXT="PROJEKT SAS - analiza zeznań podatkowych grup kapitałowych w latach 2016-2018.";
			ODS TEXT="Projekt przygotowany na zajęcia z programowania SAS.";
			ODS TEXT="Celem projektu jest dokonanie analizy i wizualizacji danych.";
			ODS TEXT="Odpowiemy na 4 postawione przez siebie pytania:";
			ODS TEXT="1) Które grupy kapitałowe złożyły zeznania podatkowe więcej niż raz na przestrzeni 3 lat?";
			ODS TEXT="2) Jak wygląda rozłożenie wysokości kwot podatku należnego zależnie od częstości występowania spółek?";
			ODS TEXT="3) Jaką część procentowo zajmują przychody, dochody i straty w poszczególnych przedziałach kwotowych?";
			ODS TEXT="4) Jakie spółki osiągają największy dochód, a jakie najmniejszy?";
			ODS TEXT="5) Ile wynoszą dane szczegółowe przychodów, dochodów i strat w poszczególnych latach (min, max, średnia, odchylenie)?";
			ODS TEXT="Rozpoczniemy od importu zbiorów i przeanalizowaniu ich struktury oraz przygotowaniu pod analizę.";
			%*Używamy makra;
			%import(2016);
			%import(2017);
			%import(2018);
			%*W makrze IMPORT możliwe argumenty to: 2016, 2017, 2018;
			ODS TEXT="Zbiory zostały zaimportowane i przygotowane do analizy.";
			ODS TEXT="W pierwszym kroku spróbujemy dowiedzieć się, które spółki występują w zeznaniach więcej niż raz.";
			%czestosc;
			ODS 
				TEXT="Poznaliśmy spis spółek wraz z ich liczbą występowania w zeznaniach.";
			ODS TEXT="Widoczne jest, że największą ilość zajmują spółki występujące jednokrotnie";
			ODS TEXT="Są to spółki które składały zeznania jednorazowo, możliwe że wcześniejsze zostały dokonane drogą papierową";
			ODS TEXT="Teraz spojrzymy na spółki występujące najmniej dwukrotnie.";
			ODS TEXT="To właśnie te spółki prawdopodobnie są wiarogodnymi podatnikami, utrzymują ciągłość w zeznaniach podatkowych";
			%czeste_spolki;
			ODS TEXT="Widzimy pełny wykaz spółek występujących najmniej dwukrotnie.";
			ODS TEXT="Ze względu na wyższą wiarygodność tych spółek będziemy się nimi zajmować w dalszej analizie";
			ODS TEXT="Zajmiemy się rozłożeniem wysokości kwot podatku należnego - w zależności od częstości występowania grup.";
			ODS TEXT="Dodatkowo zwizualizujemy procentowe rozłożenie kwot przychodów, dochodów i strat w ogólnych przedziałach.";
			%histogramy;
			ODS TEXT="Jak widzimy, grupy, które występują dwukrotnie w zeznaniach plasują się w najniższych przedziałach kwotowych podatku należnego";
			ODS TEXT="Natomiast grupy występujący najczęściej plasują się w najwyższych kwotach";
			ODS TEXT="Potwierdza to nasze założenie o wiarygodności";
			ODS TEXT="To właśnie te spółki w największym stopniu dokładają się do budżetu Państwa";
			ODS TEXT="Ciekawie się przedstawia drugi histogram, z niego możemy odczytać, że pomimo olbrzymich przychodów";
			ODS TEXT="dochody plasują się podobnej pozycji. Oznacza to, że przy wysokich przychodach, są również wysokie straty - koszty uzyskania przychodu";
			ODS TEXT="Teraz przejdziemy do badania najwyższego i najniższego dochodu w poszczególnych latach";
			%lowandtop(dochod, 2016);
			%lowandtop(dochod, 2017);
			%lowandtop(dochod, 2018);
			ODS TEXT="Możemy tutaj dostrzec pewną zależność, a mianowicie";
			ODS TEXT="Mamy 3 najczęstsze spółki, które w każdym roku utrzymują się w top 3 wysokości przychodów";
			ODS TEXT="Są to: PODATKOWA GRUPA KAPITAŁOWA PGNIG (3 razy), PODATKOWA GRUPA KAPITAŁOWA KGHM (3 razy), PODATKOWA GRUPA KAPITAŁOWA PZU (2 razy)";
			ODS TEXT="Z pewnością świadczy to o dobrym zarządzaniu finansami w tych firmach i potęgą jaką za sobą kryją";
			ODS 
				TEXT="Innym tematem projektu mogłoby być dogłębniejsze zbadanie tych spółek";
			ODS TEXT="Jeżeli chodzi o dochody minimalne to zachodzi tutaj duża różnorodność - ciężko wysunąć jakieś konkretne wnioski";
			%*W makrze LOWANDTOP możliwe argumenty to: przychody, dochod, strata 
				oraz: 2016, 2017, 2018;
			ODS TEXT="Teraz zbadamy sobie strukturę przychodu, dochodu i strat w latach 2016-2018";
			%dane_wyliczone;
			ODS TEXT="Dużą różnorodność możemy zauważyć w przychodach, dlatego spróbujemy sobie to zwizualizować";
			%zmiana(przychody);
			%*W makrze ZMIANA możliwe argumenty to: przychody, dochod, strata;
			ODS TEXT="Możemy tutaj dostrzec wzrost w 2018 roku względem 2017, powodem tego może być wzrost inflacji";
			ODS TEXT="Podobną wizualizację możemy wykonać dla dochodów oraz strat";
			ODS TEXT="Podsumowując, odpowiedzieliśmy sobie na 5 postawionych pytań";
			ODS TEXT="1) Mamy pełną listę grup kapitałowych występujących częściej niż raz w tych latach - dzięki temu możemy przeprowadzać badania na wiarygodnych podatnikach";
			ODS TEXT="2) Widzimy, że największy podatek dochodowy płacą spółki występujące najczęściej - to one w dużym stopniu zasilają budżet państwa";
			ODS TEXT="3) Dochody zajmują procentowo podobny udział nawet mimo olbrzymich przychodów - świadczy to o proporcjonalnym wzroście kosztów przychodów";
			ODS TEXT="4) Zbadaliśmy sprawę dla dochodów, możemy uruchomić makro dodatkowe dla strat czy przychodów. Są to 3 spółki (PGNIG, KGHM, PZU)";
			ODS TEXT="5) Mamy ukazane dane szczegółowe w raporcie, dodatkowo wykonaliśmy ich wizualizację.";
			ODS TEXT="Autor projektu: Szymon Pawłowski";
			ODS TEXT="W przyszłości możliwe rozszerzenie";
			ODS HTML CLOSE;