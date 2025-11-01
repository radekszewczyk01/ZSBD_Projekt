## Iteracyjne projektowanie schematu bazy danych

To była najbardziej szczegółowa część rozmowy, gdzie schemat bazy danych ewoluował na podstawie pytań Rozmówcy i wyjaśnień AI.

### Faza 1: Podstawowe definicje i relacje

* **Wyjaśnienie Gemini:** AI zdefiniowało pojęcia:
    * `ON UPDATE CASCADE ON DELETE RESTRICT` (integralność klucza obcego).
    * "Punkty MEiN" (ministerialny system oceny publikacji w Polsce).
    * "Peer review" (proces recenzji naukowej, role redaktora i 2-3 recenzentów).
    * "Tabela słownikowa" (lookup table), wyjaśniając jej cel (integralność danych, wydajność).
* **Pytania Rozmówcy, które ukształtowały model:**
    * "Czy `czy_otwarty_dostep` powinno być w `Wydawca` czy `Czasopismo`?" (Odpowiedź: `Czasopismo`).
    * "Czy artykuł może być z wielu dyscyplin?" (Odpowiedź: Tak, co wymusiło relację M:N i tabelę `Artykul_Dyscyplina`).
    * "Czy autor może być jednocześnie użytkownikiem?" (Odpowiedź: Tak, co doprowadziło do modelu 1:1 z tabelami `Autor` i `Uzytkownik`).

---

### Faza 2: Modelowanie złożonej relacji (Afiliacje)

To był kluczowy punkt zwrotny w projektowaniu.

1.  **Kluczowa obserwacja Rozmówcy:** Rozmówca zapytał o afiliacje i sam doszedł do wniosku, że kluczowa jest informacja, "do której afiliacji należał w konkretnym momencie opublikowania danego artykułu".
2.  **Potwierdzenie Gemini:** AI potwierdziło, że jest to sedno problemu i że afiliacja nie jest cechą `Autora`, lecz cechą połączenia `Artykul-Autor`.
3.  **Kluczowa obserwacja Rozmówcy:** Rozmówca dopytał, czy autor może mieć *wiele* afiliacji na *jednym* artykule.
4.  **Potwierdzenie Gemini:** AI potwierdziło, co doprowadziło do potrzeby stworzenia kolejnej tabeli M:N: `Artykul_Autor_Afiliacja`.
5.  **Propozycja optymalizacji Rozmówcy:** Rozmówca zapytał, czy zamiast klucza złożonego (`id_artykulu`, `id_autora`), nowa tabela może odnosić się do pojedynczego ID z tabeli `Artykul_Autor`.
6.  **Walidacja Gemini:** AI pochwaliło to jako doskonałe, nowoczesne rozwiązanie (tzw. klucz zastępczy) i **wygenerowało kod SQL** dla tego modelu, włączając `SERIAL PK` i `UNIQUE(id_artykulu, id_autora)`.

---

### Faza 3: Generowanie i poprawianie skryptu SQL

1.  **Wygenerowana treść:** Gemini **pomogło wygenerować** kod SQL dla tabel `RundaRecenzyjna` i `Recenzja`, bazując na regułach dostarczonych przez Rozmówcę.
2.  **Przegląd kodu:** Rozmówca wkleił kompletny, 200-linijkowy skrypt dla PostgreSQL.
3.  **Analiza i korekta Gemini:** AI przeanalizowało skrypt, potwierdziło zgodność z 3NF, ale znalazło 5 błędów (m.in. literówkę `REFERENCES REFERENCES`, błąd logiczny w `Wydawca.id_kraju`, pomieszanie składni `SERIAL` z `AUTO_INCREMENT` oraz brak `UNIQUE` w `Cytowanie`). **Gemini wygenerowało pełny, poprawiony skrypt dla PostgreSQL.**
4.  **Prośba Rozmówcy:** Rozmówca poprosił o konwersję skryptu na **MySQL**.
5.  **Wygenerowana treść:** Gemini **wygenerowało kompletny, poprawny skrypt dla MySQL**, zamieniając `SERIAL` na `INT PRIMARY KEY AUTO_INCREMENT` i naprawiając wszystkie zidentyfikowane błędy.

---

### Faza 4: Finalna normalizacja (Inicjatywa Rozmówcy)

W tej fazie Rozmówca sam zaczął aktywnie identyfikować problemy z normalizacją.

1.  **Obserwacja Rozmówcy:** Rozmówca zauważył, że kolumna `ZrodloFinansowania.typ VARCHAR(100)` powinna zostać zastąpiona tabelą słownikową.
2.  **Potwierdzenie i wygenerowanie kodu:** AI potwierdziło tę obserwację i **wygenerowało** kod dla `TypFinansowania_Slownik`.
3.  **Obserwacja Rozmówcy:** Rozmówca zapytał, czy `decyzja_redaktora VARCHAR(100)` nie jest błędem ("czy to nie jest tak, że powinna być tabela słownika?").
4.  **Potwierdzenie i wygenerowanie kodu:** AI potwierdziło, że choć technicznie nie łamie to 3NF, jest to kluczowe dla integralności danych. **Gemini wygenerowało** kod dla `Decyzja_Slownik`.
5.  **Obserwacja Rozmówcy:** Rozmówca natychmiast zauważył, że ten sam problem dotyczy `Recenzja.rekomendacja VARCHAR(100)`.
6.  **Potwierdzenie i wygenerowanie kodu:** AI potwierdziło tę trafną obserwację i **wygenerowało** kod dla `Rekomendacja_Slownik`.
7.  **Weryfikacja końcowa:** Rozmówca wkleił ostateczny, kompletny schemat, zawierający wszystkie te poprawki. Gemini przeprowadziło finalną weryfikację i **potwierdziło, że schemat jest teraz w pełni spójny, poprawny składniowo (MySQL) i logicznie.**
