# Projekt (Lightbulb)
## Informacje ogólne

**Gatunek:** Platformówka 3D, izometryczna  
**Silnik:** Godot 4.x  
**Narzędzia:** Blender, GIMP / Photoshop / Krita, Audacity  
**Platforma docelowa:** PC (Windows / Linux)

**Inspiracje:**
- Mirror’s Edge – płynny parkour / poruszanie się
- Little Nightmares – klimat, skalowanie świata

---

## Wizja gry

Gracz przemierza opuszczone dachy, wnętrza biurowców i strefy przemysłowe w celu odnalezienia drogi wyjścia z zamkniętej, zdegradowanej przestrzeni miejskiej. Miejsca sprawiają wrażenie zatrzymanych w czasie, spustoszałych i nienaturalnie pustych. Otoczenie opowiada historię.

### Rozgrywka polega na:

- przemieszczaniu się po dachach i konstrukcjach budynków (Mirror’s Edge)
- eksploracji wnętrz (korytarze, klatki schodowe, open space, piwnice, parkingi)
- unikaniu nieznanych jednostek (NPC)
- wykorzystywaniu światła jako głównej mechaniki przetrwania

### Narracja poprzez:

- rozmieszczenie obiektów
- architekturę
- światło i cień
- układ środowiska

---

## Środowisko gry

### Lokacje

- Dachy biurowców i innych budynków miejskich (klimatyzatory, anteny, szyby wentylacyjne)
- Parking wielopoziomowy (rzędy aut, słupy i rampy, migające światła)
- Wnętrza budynków (chaotyczne biuro, sale konferencyjne, korytarze, recepcje, lobby)
- Strefy techniczne (serwerownie, maszynownie, tunele serwisowe, generatory, kotłownie)

### Styl

- zimny, industrialny  
- materiały: beton, stal, szkło  
- nastrój: opresja / izolacja  
- saturation: 0.6 – 0.7  
- contrast: 1.2 – 1.4  
- exposure: obniżone  
- dodany fog (niebieski?)  
- rozmyte cienie  

---

## Paleta kolorów

### Podstawowa

| Element | Kolor | HEX | Zastosowanie |
|------|------|------|------|
| Beton (jasny) | chłodny szary | #9FA7AD | dachy, ściany |
| Beton (ciemny) | grafit | #4A4E52 | parkingi, piwnice |
| Metal | chłodny stalowy | #6B737C | konstrukcje, bariery |
| Cień | zimna czerń | #1A1D21 | brak światła |
| Mgła | zimny błękit | #2F3F4F | dystans / głębia |
| Szkło | przydymiony niebieski | #5E778A | okna, wieżowce |

### Kolory światła

| Kolor | HEX |
|------|-----|
| Ciepły biały | #FFD966 |
| Zgaszony żółty | #C9A227 |
| Zgaszony pomarańcz | #FF8C42 |
| Rdzawy blask | #C8501D |

### Efekty

| Typ | Kolor | HEX |
|-----|------|-----|
| Sylwetki cieni | ciemny granat | #0E1B2A |
| „Spojrzenia” | zimny błękit | #3ABEFF |
| Alarm | pulsujący czerwony | #900000 |

---

## Główne mechaniki – światło

- światło przyciąga wrogów (im jaśniej = łatwiejsze wykrycie)
- NPC reagują na światło
- gracz kontroluje emisyjność światła (mechanika kaptura)
- światło / bateria aktywuje elementy świata:
  - fotokomórki
  - latarnie
  - panele słoneczne
  - lustra
- światło jako strefa bezpieczna (checkpoint?)
- światło jako zasób limitowany

---

## Przeciwnicy (NPC)

**Typy:**
- patrol
- strażnik
- łowca

**Cechy:**
- reagują na światło
- brak stałej formy fizycznej
- zależnie od typu inne zachowanie / prędkość

**Walka:**
- brak
- głównie ucieczka i ukrywanie się

---

## Postać gracza

- brak dialogów
- non-human
- wyraźny kolor

**Cel:**
- ucieczka
- odnalezienie wyjścia (emergency exit?)
- zdobycie informacji o świecie?  

---

## Interakcje

- drzwi, windy – przyciski
- element blokujący drogę – popychanie
- użycie światła do rozproszenia ciemności / mgły
- checkpoint – stacja ładująca?
- zagadki logiczne wymagające użycia własnego światła

---

## Level design

**Struktura poziomu:**

`start → rozwinięcie → punkt kulminacyjny → wyjście`

1. Nauka – tutorial, podstawy ruchu i mechanik
2. Presja / eksploracja – zagadki, pułapki, platforming
3. Zakończenie – pościg / sekwencja skryptowana / scena końcowa

---

## Interfejs

- brak HUD / minimalistyczny
- tylko: ekran śmierci, pauza, menu startowe

---

## Audio

- kroki
- crackling
- pogoda / otoczenie (niskie, mroczne)
- odgłosy rur i metalu

---

## Plan działania

### Preprodukcja

- dokładny opis świata gry (styl, klimat, koncepcja)
- stworzenie GDD
- określenie:
  - głównych mechanik (skok, wspinaczka, ślizg, wallrun?)
  - stylu graficznego (low-poly / stylizowany / półrealistyczny)
  - długości gry (np. jeden poziom: 20–30 minut)
- szkice poziomów (kartka / diagramy)
- lista assetów:
  - postać gracza
  - min. 3 rodzaje platform
  - elementy otoczenia: ściany, schody, przeszkody
  - elementy interaktywne

**Rezultat:**
- gotowy dokument koncepcyjny
- szkice poziomów
- lista assetów (Word / Excel)

---

## Prototyp mechanik

**Cel:** w pełni grywalne „szare poziomy”

- dopracowanie:
  - skoku (wysokość, grawitacja)
  - przyspieszenia / hamowania
  - interakcji z platformami
- implementacja:
  - checkpointów
  - śmierci gracza
  - resetu poziomu
- proste placeholdery zamiast modeli
- testy poziomu:
  - grywalność
  - flow

---

## Assety 3D (Blender)

### Postać gracza

- model
- UV
- materiały
- rig

### Elementy świata

- platformy
- ściany
- konstrukcje
- detale sceny

---

## Animacje

- idle
- bieg
- skok
- lądowanie
- wspinaczka
- ewentualny poślizg / spadanie

**Synchronizacja:** animacja + kod

**Opcjonalnie:**
- lekkie animacje środowiska

**Rezultat:**
- komplet animacji
- poprawne przejścia w Godot (AnimationTree)

---

## Level building

- zbudowanie 1–3 poziomów
- dodanie:
  - pułapek
  - przeszkód
  - elementów timingowych
- testowanie trudności
- poprawki

---

## Oświetlenie i nastrój

- światła kierunkowe + punktowe
- cienie
- mgła / volumetric
- kolorystyka:
  - zimne barwy
  - kontrasty (np. jaśniejsza postać)
- post-processing (Godot)

---

## Audio (implementacja)

- kroki
- skok
- lądowanie
- ambient
- prosta muzyka (tło)

---

## Optymalizacja i testy

- poprawa FPS
- zmniejszenie ilości polygonów (jeśli trzeba)
- usunięcie błędów
- testy użytkownika (2–3 osoby)
