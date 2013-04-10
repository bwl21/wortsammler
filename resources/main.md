% Wortsammler sample document
% Bernhard Weichel; and others
% date

# Introduction

This is a sample document for Wortsammler

# Anforderung an Dokumentenaufbereiter

-   [RS_Comp_003] **Steuerung Dokumentenzusammenstellung**
    {Dokumentenzusammenstellungen soll über ein manifest
    ->[RS_Comp_007] gesteuert werden.

    -   Die Manifeste sollen als Laufzeitparameter übergeben werden
    -   Das Manifest enthält auch die Ausgabedatei

    }(RS_DM_014, RS_DM_010, RS_DM_005)

-   [RS_Comp_004] **Prozessierung Einzeldokument** {Soll Dokumente
    verschiedenen Umfangs erzeugen können:

    -   einzelnes Files
    -   zu Prüfzwecken

    Steuerung soll über Konfiguration (Manifest) erfolgen
    ->[RS_Comp_007].

    }()

-   [RS_Comp_005] **Erstellung Loseblattsammlung** {Soll Dokumente
    verschiedenen Umfangs erzeugen können:

    -   kann aus dem Manifest errechnet werden ->[RS_Comp_007]

    }()

-   [RS_Comp_006] **Inkrementelle Verarbeitung** {Soll nur auf
    geänderte Dokumente reagieren können:

    -   ähnlich wie make/rake

    }()

-   [RS_Comp_007] **Anforderungen an Manifest** {Folgende
    Anforderungen gelten für das Manifest
    -   einfach bearbeiten - nur liste der Files
    -   Markdown-lite
    -   Yaml

    Inhalte im Manifest sind

    -   Name der Konfiguration
    -   Ausgabeverzeichnis
    -   Ausgabeformat
    -   Name des generierten Dokumentes
    -   Formate in denen das Dokument generiert wird. Werte hierfür
        ergeben sich aus den Anforderungen an die Aufbereitet
    -   zu verarbeitende Eingabedateien. Diese werden in der Reihenfolge
        verarbeitet wie sie aufgeführt sind.
    -   Optionen für die jeweiligen Formate.
    -   zu bearbeitende Zielgruppen ->[RS_Comp_008]

    <!-- -->

    Beispiel für ein manifest

         -
           :name:  komplett
           :outdir: ../ZGEN_Documents
           :outname: RS_Requirements-Ngopm
           :format:
             - pdf
             - html
             - rtf
             - docx
             - latex

           :lang: german  

           :vars:
               :lang: german

           :editions:
             :intern: 
                 :title: Interne Ausgabe
                 :filepart: _intern 
             :extern: 
                 :title: Externe Ausgabe
                 :filepart: _extern
             :mieter: 
                 :title: Ausgabe für Mieter
                 :filepart: _mieter
             :ea: 
                 :title: Ausgabe für ehrenamtliche Mitarbeiter
                 :filepart: _ma-ehrenamtlich
             :ha: 
                 :title: Ausgabe für hauptamtliche Mitarbeiter
                 :filepart: _ma-hauptamtlich
             :1: 
                 :title: Ausgabe für erste hauptamtliche Mitarbeiter
                 :filepart: _ma-hauptamtlich-1

           :input: 
             - ../RS_Process/RS_Process.md 
             - ../RS_Tooling/RS_Tooling.md 
             - ../RS_Tooling/RS_MarkdownCleaner.md 
             - ../RS_Tooling/RS_MarkdownEditor.md 
             - ../RS_Tooling/RS_DocumentComposer.md  
             - ../TPL_DirectoryStructure/TPL_DirectoryStructure.md
             - ../TR_Installation/TR_Installation.md
             - ../TR_Installation/TR_Proo-Handbuch.md
             - ../ZGEN_RequirementsTracing/ZGEN_Reqtrace.md

           :snippets:
             - ../TS_Markdown/TS_Snippets.yaml
             - ../TS_Markdown/TS_MoreSnippets.yaml

    }(RS_Comp_003)

## Zielgruppenspezifische Ausgaben

Dieser Abschnitt behandelt speziell die Anforderungen an flexible
Dokumentenausgabe

-   [RS_Comp_001] **Flexibler Dokumentumfang** {Soll Dokumente
    verschiedenen Umfangs erzeugen können:

    -   einzelnes Files
    -   Zusammengestelltes Dokument

    }(RS_Comp_003)

-   [RS_Comp_002] **Flexible Dokumentendarstellung** {Sollte Dokumente
    in verschiedener Darstellung erzeugen können:
    -   Seitenlayout
    -   Detaillierungsgrad (z.B. RequirementsMarken ausblenden) }
        (RS_Comp_003)

-   [RS_Comp_008] **Zielgruppenspezifische Ausgaben (Editionen)** { Es
    soll möglich sein Zielgruppenspezifische Ausgaben zu erstellen.

    -   Dabei wird die Zielgruppe durch eine spezifische Zeichenkette
        umgeschaltet (Durchstreichung), die auch in standard Markdown
        Programmen eine sinnvolle Ausgabe liefert:

        `~~ED intern extern~~` ab hier gilt: Text erscheint in Ausgabe
        `intern` als auch in `extern`

        Es handelt sich also um ein durchgestrichenes Muster als
        regulärer Ausdruck

            ~~ED((\s* \S+)*)~~

    -   Die Umschaltung wirkt ab einschliesslich der Zeile, die die
        Umschaltung enthält, bis zum Aufruf einer neuen Umschaltung.

    -   Die möglichen Zielgruppen werden im Manifest festgelegt
        ->[RS_Comp_007] daselbst Eintrag `:editions:`

    -   Eine vorgegebene Zielgruppe `all` erzeugt keine spezifische
        Ausgabe. Sie kennzeichnet vielmehr Inhalte, die in **allen**
        Ausgaben gleichermassen enthalten sind.

    -   Bei einer Aufteilung auf mehrere Dateien wird empfohlen am Ende
        einer jeden Datei auf `all` zu schalten. Dadurch wird das System
        einfache wartbar.

    }(RS_Comp_003)

    Alternativen für die Umschaltung sind:

    \marginpar{intern}

    -   ~~ED intern extern~~ und so geht es weiter

    -   ^ZG intern extern^ und nun kommt der text der nur extern ist

    \marginpar{extern}

    -   ~ZG intern extern~ und hier ist der text der nur intern ist

    -   <!-- ZG intern extern --> und nun geht es weiter

    \marginpar{intern}

    -   und nun geht es intern weiter Gelaber und weiter

-   [RS_Comp_009] **Gesamtausgabe mit allen Texten zur Prüfung**
    {Sollte Dokumente Eine Gesamtausgabe mit allen Texten zur
    Überprüfung soll erstellt werden. In diesem Fall werden die Ausgaben
    am Rand notiert. }(RS_Comp_003)

-   [RS_Comp_010] **Erstellung aller Ausgaben mit einem Befehl** {Es
    sollen immer alle Ausgaben gleichermassen generiert werden. Dabei
    gilt:

    -   Der Dateiname für die generierten Dokumente bildet sich nach

        `{:outname:}_{:edition:.:filepart:}.{format}`

    -   In der Kopfzeile des Dokumentes wird `:edition:.:title:`
        eingefügt, so dass die Ausgabe auf jeder Seite identifiziert
        werden kann.

    Ohne Angabe einer Zielgruppe bzw. mit der Angabe `all` soll
    wortsammler alle Ausgaben erstellen.

    Die Angabe einer einzelnen Zielgruppe erstellt dann auch nur die
    gewählte Ausgabe.

    }(RS_Comp_003)

## Processing TODO - open issues

Paragraphs like starting with

    TODO: #13 do something are used to manage the open issues   

## Processing the traceables

## Including Files

-   [RS_Comp_011] **including Plain pdf-Pages**{ PDF pages can be
    included by

    `~~PDF "lib/01234_particularPdf.pdf" "Das ist der Eintrag im Inhaltsverzeichnis" 1 2-4~~`

    It is done in a markdown verbatim section. By this, Pandoc does not
    add linebreaks in the command such that it can be processed with
    regular expressions.

    }(RS_Comp_003)

-   [RS_Comp_014] **Including markdown files** {

    `~~MD "lib/01234/xxxx/yyyy.md"~~`

    will be replaced by the content of the argument. It shold even work
    inline.

    }(RS_Comp_003)

## Handling Text Snippets

-   [RS_Comp_012] **Including text Snippets**{ Text Snippts can be
    included by

        `~~SN {symbol}~~`

    The snippets are taken from one of the snippet databases declared in
    the manifest ->[RS_Comp_007] according to the format in
    ->[RS_Comp_013]. }()

-   [RS_Conp_013] **Defining text Snippets** {

    Text snippets are defined as a yaml file in the following format:

        :Snippet1: Das ist Snippet 1

        :Snippet2: |- Das ist snippet 2. Es enthält sogar eine Liste

                *   Das ist item 1 in Snippet 2

                *   Das ist item 2 in Snippet 2

    }(RS_Comp_003)

