/*
HBNFEDACTE - DOCUMENTO AUXILIAR DO CTE
Fontes originais do projeto hbnfe em https://github.com/fernandoathayde/hbnfe

2016.09.24.1100 - Incluso, faltam altera��es
2016.09.25.0940 - Ainda n�o houve gera��o de PDF
*/

#include "common.ch"
#include "hbclass.ch"
#include "harupdf.ch"
#ifndef __XHARBOUR__
#include "hbwin.ch"
#include "hbzebra.ch"
#endif

CREATE CLASS hbnfeDacte

   METHOD Execute( cXml, cFilePDF )
   METHOD BuscaDadosXML()
   METHOD GeraPDF( cFilePDF )
   METHOD NovaPagina()
   METHOD Cabecalho()

   DATA nLarguraDescricao
   DATA nLarguraCodigo
   DATA cTelefoneEmitente INIT ""
   DATA cSiteEmitente     INIT ""
   DATA cEmailEmitente    INIT ""
   DATA cXML
   DATA cChave
   DATA aIde
   DATA aCompl
   DATA aObsCont
   DATA aEmit
   DATA aRem
   DATA ainfNF
   DATA ainfNFe
   DATA ainfOutros
   DATA aDest
   DATA aLocEnt
   DATA aPrest
   DATA aComp
   DATA aIcms00
   DATA aIcms20
   DATA aIcms45
   DATA aIcms60
   DATA aIcms90
   DATA aIcmsUF
   DATA aIcmsSN
   DATA vTotTrib
   DATA cAdfisco
   DATA aInfCarga
   DATA aInfQ
   DATA aSeg
   DATA aRodo
   DATA aMoto
   DATA aProp
   DATA aValePed
   DATA aVeiculo
   DATA aProtocolo
   DATA aExped
   DATA aReceb
   DATA aToma

   DATA aICMSTotal
   DATA aISSTotal
   DATA aRetTrib
   DATA aTransp
   DATA aVeicTransp
   DATA aReboque
   DATA cCobranca
   DATA aInfAdic
   DATA aObsFisco
   DATA aExporta
   DATA aCompra
   DATA aInfProt
   DATA aInfCanc //

   DATA aItem
   DATA aItemDI
   DATA aItemAdi
   DATA aItemICMS
   DATA aItemICMSPart
   DATA aItemICMSST
   DATA aItemICMSSN101
   DATA aItemICMSSN102
   DATA aItemICMSSN201
   DATA aItemICMSSN202
   DATA aItemICMSSN500
   DATA aItemICMSSN900
   DATA aItemIPI
   DATA aItemII
   DATA aItemPIS
   DATA aItemPISST
   DATA aItemCOFINS
   DATA aItemCOFINSST
   DATA aItemISSQN

   DATA cFonteNFe
   DATA cFonteCode128            // Inserido por Anderson Camilo em 04/04/2012
   DATA cFonteCode128F           // Inserido por Anderson Camilo em 04/04/2012
   DATA oPdf
   DATA oPdfPage
   DATA oPdfFontCabecalho
   DATA oPdfFontCabecalhoBold
   DATA nLinhaPDF
   DATA nLarguraBox INIT 0.5
   DATA lLaser INIT .T.
   DATA lPaisagem
   DATA cLogoFile
   DATA nLogoStyle // 1-esquerda, 2-direita, 3-expandido

   DATA nItensFolha
   DATA nLinhaFolha
   DATA nFolhas
   DATA nFolha

   DATA lValorDesc INIT .F.
   DATA nCasasQtd INIT 2
   DATA nCasasVUn INIT 2
   DATA cRetorno

   ENDCLASS

METHOD Execute( cXml, cFilePDF ) CLASS hbnfeDaCte

   hb_Default( ::lLaser, .T. )
   hb_Default( ::cFonteNFe, "Times" )

   IF cXml == NIL
      ::cRetorno := "N�o informado texto do XML"
      RETURN ::cRetorno
   ENDIF

   ::cXML   := cXml
   ::cChave := SubStr( ::cXML, At( 'Id=', ::cXML ) + 3 + 4, 44 )

   IF !::buscaDadosXML()
      RETURN ::cRetorno
   ENDIF

   ::lPaisagem          := .F.
   ::nLarguraDescricao  := 39
   ::nLarguraCodigo     := 13

   IF ! ::GeraPdf( cFilePDF )
      ::cRetorno := "Problema ao gerar o PDF !"
      RETURN ::cRetorno
   ENDIF

   ::cRetorno := "OK"

   RETURN ::cRetorno

METHOD BuscaDadosXML() CLASS hbnfeDaCte

   LOCAL cIde, cCompl, cEmit, cRem, cinfNF, cinfNFe, cinfOutros, cDest, cLocEnt, cPrest, cComp, cImp, cText, oElement
   LOCAL cIcms00, cIcms20, cIcms45, cIcms60, cIcms90, cIcmsUF, cIcmsSN
   LOCAL cinfCTeNorm, cInfCarga, cSeg, cRodo, cVeiculo, cProtocolo, cExped
   LOCAL cReceb, cInfQ, cValePed, cMoto, cProp

   cIde := XmlNode( ::cXml, "ide" )
   ::aIde := hb_Hash()
   FOR EACH oElement IN { "cUF", "cCT", "CFOP", "natOp", "forPag", "mod", "serie", "nCT", "dhEmi", "tpImp", "tpEmis", "cDV", "tpAmb", ;
         "tpCTe", "procEmi", "verProc", "cMunEnv", "xMunEnv", "UFEnv", "modal", "tpServ", "cMunIni", "xMunIni", "UFIni", "cMunFim", "xMunFim", "UFFim", ;
         "retira", "xDetRetira" }
      ::aIde[ oElement ] := XmlNode( cIde, oElement )
   NEXT
   cIde := XmlNode( cIde, "toma03" )
   ::aIde[ "toma" ] := XmlNode( cIde, "toma" )

   cCompl := XmlNode( ::cXml, "compl" )
   ::aCompl := hb_Hash()
   ::aCompl[ "xObs" ] := XmlNode( cCompl, "xObs" )
   ::aObsCont := hb_Hash()
   ::aObsCont[ "xTexto" ] := XmlNode( cCompl, "xTexto" )

   cEmit := XmlNode( ::cXml, "emit" )
   ::aEmit := hb_Hash()
   FOR EACH oELement IN { "CNPJ", "IE", "xNome", "xFant", "fone" }
      ::aEmit[ oElement ] := XmlNode( cEmit, oElement )
   NEXT
   ::aEmit[ "xNome" ] := XmlToSTring( "xNome" )
   ::cTelefoneEmitente  := SoNumeros( XmlNode( cEmit, "fone" ) )
   IF ! Empty( ::cTelefoneEmitente )
      ::cTelefoneEmitente := Transform( ::cTelefoneEmitente, "@E (99) 9999-9999" )
   ENDIF
   cEmit := XmlNode( cEmit, "enderEmit" )
   FOR EACH oElement IN { "xLgr", "nro", "xCpl", "xBairro", "cMun", "xMun", "CEP", "UF" }
      ::aEmit[ oElement ] := XmlNode( cEmit, oElement )
   NEXT

   cRem := XmlNode( ::cXml, "rem" )
   ::aRem := hb_Hash()
   FOR EACH oElement IN { "CNPJ", "CPF", "IE", "xNome", "xFant", "fone", "xLgr", "nro", "xCpl", "xBairro", "cMun", "xMun", "CEP", "UF", "cPais", "xPais" }
      ::aRem[ oElement ] := XmlNode( cRem, oElement )
   NEXT
   ::aRem[ "xNome" ] := XmlToString( ::aRem[ "xNome" ] )
   cRem := XmlNode( ::cXml, "infDoc" )
   ::ainfNF := {}
   cText := cRem
   DO WHILE "<infNF" $ cText .AND. "</infNF" $ cText
      cinfNF := XmlNode( cText, "infNF" )
      cText  := SubStr( cText, At( "</infNF", cText ) + 8 )
      AAdd( ::ainfNF, { ;
         XmlNode( cInfNf, "nRoma" ), ;
         XmlNode( cInfNf, "nPed" ), ;
         XmlNode( cInfNf, "mod" ), ;
         XmlNode( cInfNf, "serie" ), ;
         XmlNode( cInfNf, "nDoc" ), ;
         XmlNode( cInfNf, "dEmi" ), ;
         XmlNode( cInfNf, "vBC" ), ;
         XmlNode( cInfNf, "vICMS" ), ;
         XmlNode( cInfNf, "vBCST" ), ;
         XmlNode( cInfNf, "vST" ), ;
         XmlNOde( cInfNf, "vProd" ), ;
         XmlNode( cInfNf, "vNF" ), ;
         XmlNode( cInfNf, "nCFOP" ), ;
         XmlNode( cInfNf, "nPeso" ), ;
         XmlNode( cInfNf, "PIN" ) } )
   ENDDO

   ::ainfNFe := {}
   cText := XmlNode( ::cXml, "infDoc" ) // versao 2.0
   DO WHILE "<infNFe" $ cText .AND. "</infNFe" $ cText
      cinfNFe := XmlNode( cText, "infNFe" )
      cText   := SubStr( cText, At( "</infNFe", cText ) + 9 )
      AAdd( ::ainfNFe, { ;
         XmlNode( cInfNFE, "chave" ), + ;
         XmlNode( cInfNFE, "PIN" ) } )
   ENDDO

   ::ainfOutros := {}
   cText := XmlNode( ::cXml, "infDoc" ) // versao 2.0
   DO WHILE "<infOutros" $ cText .AND. "</infOutros" $ cText
      cinfOutros := XmlNode( cText, "infOutros" )
      cText      := SubStr( cText, At( "</infOutros", cText ) + 12 )
      AAdd( ::ainfOutros, { ;
         XmlNode( cInfOutros, "tpDoc" ), ;
         XmlNode( cInfOutros, "descOutros" ), ;
         XmlNode( cInfOutros, "nDoc" ), ;
         XmlNode( cInfOutros, "dEmi" ), ;
         XmlNode( cInfOutros, "vDocFisc" ) } )
   ENDDO

   cDest := XmlNode( ::cXml, "dest" )
   ::aDest := hb_Hash()
   FOR EACH oElement IN { "CNPJ", "CPF", "IE", "xNome", "fone", "ISUF", "email" }
      ::aDest[ oElement ] := XmlNode( cDest, oElement )
   NEXT
   ::aDest[ "xNome" ] := XmlToString( ::aDest[ "xNome" ] )
   ::aDest[ "email" ] := XmlToString( ::aDest[ "email" ] )

   cDest := XmlNode( cDest, "enderDest" )
   FOR EACH oElement IN { "xLgr", "nro", "xCpl", "xBairro", "cMun", "xMun", "UF", "CEP", "cPais", "xPais" }
      ::aDest[ oElement ] := XmlNode( cDest, oElement )
   NEXT

   clocEnt := XmlNode( cDest, "locEnt" )
   ::alocEnt := hb_Hash()
   FOR EACH oElement IN { "CNPJ", "CPF", "xNome", "xLgr", "nro", "xCpl", "xBairro", "xMun", "UF" }
      ::aLocEnt[ oElement ] := XmlNode( cLocEnt, oElement )
   NEXT

   cExped := XmlNode( ::cXml, "exped" )
   ::aExped := hb_Hash()
   FOR EACH oElement IN { "CNPJ", "CPF", "IE", "xNome", "fone", "email" }
      ::aExped[ oElement ] := XmlNode( cExped, oElement )
   NEXT
   ::aExped[ "xNome" ] := XmlToString( ::aExped[ "xNome" ] )
   ::aExped[ "email" ] := XmlToString( ::aExped[ "email" ] )

   cExped := XmlNode( cExped, "enderExped" )
   FOR EACH oElement IN { "xLgr", "nro", "xCpl", "xBairro", "cMun", "xMun", "UF", "CEP", "cPais", "xPais" }
      ::aExped[ oElement ] := XmlNode( cExped, oElement )
   NEXT

   cReceb := XmlNode( ::cXml, "receb" )
   ::aReceb := hb_Hash()
   FOR EACH oElement IN { "CNPJ", "CPF", "IE", "xNome", "fone", "email" }
      ::aReceb[ oElement ] := XmlNode( cReceb, oElement )
   NEXT
   ::aReceb[ "xNome" ] := XmlToString( ::aReceb[ "xNome" ] )
   ::aReceb[ "email" ] := XmlToString( ::aReceb[ "email" ] )

   cReceb := XmlNode( cReceb, "enderReceb" )
   FOR EACH oElement IN { "xLgr", "nro", "xCpl", "xBairro", "cMun", "xMun", "UF", "CEP", "cPais", "xPais" }
      ::aReceb[ oElement ] := XmlNode( cReceb, oElement )
   NEXT

   cPrest := XmlNode( ::cXml, "vPrest" )
   ::aPrest := hb_Hash()
   FOR EACH oElement IN { "vTPrest", "vRec" }
      ::aPrest[ oElement ] := XmlNOde( cPrest, oElement )
   NEXT

   ::aComp := {}
   cPrest  := XmlNode( ::cXml, "vPrest" )
   cText   := cPrest
   DO WHILE "<Comp" $ cText .AND. "</Comp" $ cText
      cComp := XmlNode( cText, "Comp" )
      cText := SubStr( cText, At( "</Comp", cText ) + 7 )
      AAdd( ::aComp, { ;
         XmlNode( cComp, "xNome" ), ;
         XmlNode( "vComp" ) } )
   ENDDO

   cImp := XmlNode( ::cXml, "imp" )

   cIcms00 := XmlNode( cImp, "ICMS00" )
   ::aIcms00 := hb_Hash()
   FOR EACH oElement IN { "CST", "vBC", "pICMS", "vICMS" }
      ::aIcms00[ oElement ] := XmlNode( cIcms00, oElement )
   NEXT

   cIcms20 := XmlNode( cImp, "ICMS20" )
   ::aIcms20 := hb_Hash()
   FOR EACH oElement IN { "CST", "vBC", "pRedBC", "pICMS", "vICMS" }
      ::aIcms20[ oElement ] := XmlNode( cIcms20, oElement )
   NEXT

   cIcms45 := XmlNode( cImp, "ICMS45" )
   ::aIcms45 := hb_Hash()
   ::aIcms45[ "CST" ] := XmlNode( cIcms45, "CST" ) // NFE 2.0

   cIcms60 := XmlNode( cImp, "ICMS60" )
   ::aIcms60 := hb_Hash()
   FOR EACH oElement IN { "CST", "vBCSTRet", "vICMSSTRet", "pICMSSTRet", "vCred" }
      ::aIcms60[ oElement ]  := XmlNode( cIcms60, oElement )
   NEXT

   cIcms90 := XmlNode( cImp, "ICMS90" )
   ::aIcms90 := hb_Hash()
   FOR EACH oElement IN { "CST", "pRedBC", "vBC", "pICMS", "vICMS", "vCred" }
      ::aIcms90[ oElement ] := XmlNode( cICms90, oElement )
   NEXT

   cIcmsUF := XmlNode( cImp, "ICMSOutraUF" )
   ::aIcmsUF := hb_Hash()
   FOR EACH oElement IN { "CST", "pRedBCOutraUF", "vBCOutraUF", "pICMSOutraUF", "vICMSOutraUF" }
      ::aIcmsUF[ oElement ] := XmlNode( cIcmsUF, oElement )
   NEXT

   cIcmsSN := XmlNode( cImp, "ICMSSN" )
   ::aIcmsSN := hb_Hash()
   ::aIcmsSN[ "indSN" ] := XmlNode( cIcmsSN, "indSN" ) // NFE 2.0
   ::cAdFisco := XmlNode( cImp, "infAdFisco" )

   ::vTotTrib  := XmlNode( ::cXml, "vTotTrib" )

   cinfCTeNorm := XmlNode( ::cXml, "infCTeNorm" )
   cinfCarga   := XmlNode( cInfCteNorm, "infCarga" )
   ::aInfCarga := hb_Hash()
   FOR EACH oElement IN { "vCarga", "proPred", "xOutCat" }
      ::aInfCarga[ oElement ] := XmlNode( cInfCarga, oElement )
   NEXT

   ::aInfQ := {}
   cText := XmlNode( cInfCteNorm, "infCarga" )
   DO WHILE "<infQ" $ cText .AND. "</infQ" $ cText
      cInfQ := XmlNode( cText, "infQ" )
      cText := SubStr( cText, At( "</infQ", cText ) + 7 )
      AAdd( ::aInfQ, { ;
         XmlNode( cInfQ, "cUnid" ), + ;
         XmlNode( cInfQ, "tpMed" ), + ;
         XmlNode( cInfQ, "qCarga" ) } )
   ENDDO

   cSeg := XmlNode( cInfCTeNorm, "seg" )
   ::aSeg := hb_Hash()
   FOR EACH oElement IN { "respSeg", "xSeg", "nApol", "nAver", "vCarga" }
      ::aSeg[ oElement ] := XmlNode( cSeg, oElement )
   NEXT

   cRodo := XmlNode( cInfCteNorm, "rodo" )
   ::aRodo := hb_Hash()
   FOR EACH oElement IN { "RNTRC", "dPrev", "lota", "CIOT", "nLacre" }
      ::aRodo[ oElement ] := XmlNode( oElement, cRodo )
   NEXT

   cMoto := XmlNode( cInfCteNorm, "moto" )
   ::aMoto := hb_Hash()
   FOR EACH oElement IN { "xNome", "CPF" }
      ::aMoto[ oElement ] := XmlNode( cMoto, oElement )
   NEXT

   cValePed := XmlNode( cRodo, "valePed" )
   ::aValePed := hb_Hash()
   FOR EACH oElement IN { "CNPJForn", "nCompra", "CNPJPg" }
      ::aValePed[ oElement ] := XmlNode( cValePed, oElement )
   NEXT

   cProp := XmlNode( cRodo, "prop" )
   ::aProp := hb_Hash()
   FOR EACH oElement IN { "CPF", "CNPJ", "RNTRC", "xNome", "IE", "UF", "tpProp" }
      ::aProp[ oElement ] := XmlNode( cProp, oElement )
   NEXT

   ::aVeiculo := {}
   cText := XmlNode( cinfCteNorm, "rodo" )
   DO WHILE "<veic" $ cText .AND. "</veic" $ cText
      cVeiculo := XmlNode( cText, "veic" )
      cText    := SubStr( cText, At( "</veic", cText ) + 7 )
      AAdd( ::aVeiculo, { ;
         XmlNode( cVeiculo, "cInt" ), ;
         XmlNode( cVeiculo, "RENAVAM" ), ;
         XmlNode( cVeiculo, "placa" ), ;
         XmlNode( cVeiculo, "tara" ), ;
         XmlNode( cVeiculo, "capKG" ), ;
         XmlNode( cVeiculo, "capM3" ), ;
         XmlNode( cVeiculo, "tpProp" ), ;
         XmlNode( cVeiculo, "tpVeic" ), ;
         XmlNode( cVeiculo, "tpRod" ), ;
         XmlNode( cVeiculo, "tpCar" ), ;
         XmlNode( cVeiculo, "UF" ) } )
   ENDDO

   cProtocolo := XmlNode( ::cXml, "infProt" )
   ::aProtocolo := hb_Hash()
   FOR EACH oElement IN { "nProt", "dhRecbto" }
      ::aProtocolo[ oElement ] := XmlNode( cProtocolo, oElement )
   NEXT

   DO CASE
   CASE ::aIde[ 'toma' ] = '0' ; ::aToma := ::aRem
   CASE ::aIde[ 'toma' ] = '1' ; ::aToma := ::aExped
   CASE ::aIde[ 'toma' ] = '2' ; ::aToma := ::aReceb
   CASE ::aIde[ 'toma' ] = '3' ; ::aToma := ::aDest
   ENDCASE

   RETURN .T.

METHOD GeraPDF( cFilePDF ) CLASS hbnfeDaCte

   ::oPdf := HPDF_New()
   If ::oPdf == NIL
      ::cRetorno := "Falha da cria��o do objeto PDF !"
      RETURN .F.
   ENDIF
   HPDF_SetCompressionMode( ::oPdf, HPDF_COMP_ALL )
   IF ::cFonteNFe == "Times"
      ::oPdfFontCabecalho     := HPDF_GetFont( ::oPdf, "Times-Roman", "CP1252" )
      ::oPdfFontCabecalhoBold := HPDF_GetFont( ::oPdf, "Times-Bold", "CP1252" )
   ELSE
      ::oPdfFontCabecalho     := HPDF_GetFont( ::oPdf, "Courier", "CP1252" )
      ::oPdfFontCabecalhoBold := HPDF_GetFont( ::oPdf, "Courier-Bold", "CP1252" )
   ENDIF

#ifdef __XHARBOUR__
   // Inserido por Anderson Camilo em 04/04/2012
   ::cFonteCode128  := HPDF_LoadType1FontFromFile( ::oPdf, 'fontes\Code128bWinLarge.afm', 'fontes\Code128bWinLarge.pfb' )   // Code 128
   ::cFonteCode128F := HPDF_GetFont( ::oPdf, ::cFonteCode128, "WinAnsiEncoding" )
#endif

   ::nFolha := 1
   ::novaPagina()
   ::cabecalho()

   HPDF_SaveToFile( ::oPdf, cFilePDF )
   HPDF_Free( ::oPdf )

   RETURN .T.

METHOD NovaPagina() CLASS hbnfeDaCte

   LOCAL nRadiano, nAngulo

   ::oPdfPage := HPDF_AddPage( ::oPdf )

   HPDF_Page_SetSize( ::oPdfPage, HPDF_PAGE_SIZE_A4, HPDF_PAGE_PORTRAIT )

   ::nLinhaPdf := HPDF_Page_GetHeight( ::oPDFPage ) - 3     // Margem Superior
   nAngulo := 45                   /* A rotation of 45 degrees. */

   nRadiano := nAngulo / 180 * 3.141592 /* Calcurate the radian value. */

   IF ::aIde[ "tpAmb" ] = "2" .OR. ::aProtocolo[ "nProt" ] = Nil

      HPDF_Page_SetFontAndSize( ::oPdfPage, ::oPdfFontCabecalhoBold, 30 )
      HPDF_Page_BeginText( ::oPdfPage )
      HPDF_Page_SetTextMatrix( ::oPdfPage, Cos( nRadiano ), Sin( nRadiano ), -Sin( nRadiano ), Cos( nRadiano ), 15, 100 )
      HPDF_Page_SetRGBFill( ::oPdfPage, 0.75, 0.75, 0.75 )
      HPDF_Page_ShowText( ::oPdfPage, "AMBIENTE DE HOMOLOGA��O - SEM VALOR FISCAL" )
      HPDF_Page_EndText( ::oPdfPage )

      HPDF_Page_SetRGBStroke( ::oPdfPage, 0.75, 0.75, 0.75 )
      hbNFe_Line_Hpdf( ::oPdfPage, 15, 100, 550, 630, 2.0 )

      HPDF_Page_SetRGBStroke( ::oPdfPage, 0, 0, 0 ) // reseta cor linhas

      HPDF_Page_SetRGBFill( ::oPdfPage, 0, 0, 0 ) // reseta cor fontes

   ENDIF

   IF ::aIde[ "tpAmb" ] = "1"
/*
      IF ::aInfCanc[ "nProt" ] <> Nil

       HPDF_Page_SetFontAndSize( ::oPdfPage, ::oPdfFontCabecalhoBold, 30 )
       HPDF_Page_BeginText(::oPdfPage)
       HPDF_Page_SetTextMatrix(::oPdfPage, cos(nRadiano), sin(nRadiano), -sin(nRadiano), cos(nRadiano), 15, 100)
       HPDF_Page_SetRGBFill(::oPdfPage, 1, 0, 0)
       HPDF_Page_ShowText(::oPdfPage, ::aInfCanc[ "xEvento" ])
       HPDF_Page_EndText(::oPdfPage)

       HPDF_Page_SetRGBStroke(::oPdfPage, 0.75, 0.75, 0.75)
       IF ::lPaisagem = .T. // paisagem
          hbnfe_Line_hpdf( ::oPdfPage, 15, 95, 675, 475, 2.0)
       ELSE
          hbnfe_Line_hpdf( ::oPdfPage, 15, 95, 550, 630, 2.0)
       ENDIF

       HPDF_Page_SetRGBStroke(::oPdfPage, 0, 0, 0) // reseta cor linhas

       HPDF_Page_SetRGBFill(::oPdfPage, 0, 0, 0) // reseta cor fontes

  ENDIF
*/
   ENDIF

   RETURN NIL

METHOD Cabecalho() CLASS hbnfeDaCte

   LOCAL oImage
   LOCAL aModal     := { 'Rodovi�rio', 'A�reo', 'Aquavi�rio', 'Ferrovi�rio', 'Dutovi�rio' }
   LOCAL aTipoCte   := { 'Normal', 'Compl.Val', 'Anul.Val.', 'Substituto' }
   LOCAL aTipoServ  := { 'Normal', 'Subcontrata��o', 'Redespacho', 'Redesp. Int.' }
   LOCAL aTomador   := { 'Remetente', 'Expedidor', 'Recebedor', 'Destinat�rio' }
   LOCAL aPagto     := { 'Pago', 'A pagar', 'Outros' }
   LOCAL aUnid      := { 'M3', 'KG', 'TON', 'UN', 'LI', 'MMBTU' }
   LOCAL aResp      := { 'Remetente', 'Expedidor', 'Recebedor', 'Destinat�rio', 'Emitente do CT-e', 'Tomador de Servi�o' }
   LOCAL aTipoCar   := { 'n�o aplic�vel', 'Aberta', 'Fechada/Ba�', 'Granelera', 'Porta Container', 'Sider' }
   LOCAL cOutros    := ''
   LOCAL cEntrega   := ''
   LOCAL aObserv    := {}
   LOCAL cMensa
   LOCAL nLinha
   LOCAL nBase      := ''
   LOCAL nAliq      := ''
   LOCAL nValor     := ''
   LOCAL nReduc     := ''
   LOCAL nST        := ''
   LOCAL DASH_MODE3 := { 8, 7, 2, 7 }
   LOCAL I, oElement, hZebra

   // box do logotipo e dados do emitente
   hbnfe_Box_hpdf( ::oPdfPage,  003, ::nLinhaPdf - 119, 295, 119, ::nLarguraBox )

   IF ! Empty( ::cLogoFile )
      oImage := HPDF_LoadJpegImageFromFile( ::oPdf, ::cLogoFile )
      HPDF_Page_DrawImage( ::oPdfPage, oImage, 115, ::nLinhaPdf - ( 52 + 1 ), 100, 052 )
   ENDIF
   IF Len( ::aEmit[ "xNome" ] ) <= 25
      hbnfe_Texto_hpdf( ::oPdfPage,  3, ::nLinhaPdf - 056, 295, Nil, ::aEmit[ "xNome" ], HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 12 )
   ELSE
      hbnfe_Texto_hpdf( ::oPdfPage,  3, ::nLinhaPdf - 056, 295, Nil, ::aEmit[ "xNome" ], HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 10 )
   ENDIF
   hbnfe_Texto_hpdf( ::oPdfPage,  6, ::nLinhaPdf - 070, 295, Nil, ::aEmit[ "xLgr" ] + " " + iif( ::aEmit[ "nro" ]  != Nil, ::aEmit[ "nro" ], '' ) + " " + iif( ::aEmit[ "xCpl" ] != Nil, ::aEmit[ "xCpl" ], '' ), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage,  6, ::nLinhaPdf - 078, 295, Nil, ::aEmit[ "xBairro" ] + " - " + TRANSF( ::aEmit[ "CEP" ], "@R 99999-999" ), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage,  6, ::nLinhaPdf - 086, 295, Nil, ::aEmit[ "xMun" ] + " - " + ::aEmit[ "UF" ], HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage,  6, ::nLinhaPdf - 094, 295, Nil, 'Fone/Fax:(' + SubStr( ::aEmit[ "fone" ], 1, 2 ) + ')' + SubStr( ::aEmit[ "fone" ], 3, 4 ) + '-' + SubStr( ::aEmit[ "fone" ], 7, 4 ), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage,  6, ::nLinhaPdf - 107, 295, Nil, 'CNPJ/CPF:' + TRANSF( ::aEmit[ "CNPJ" ], "@R 99.999.999/9999-99" ) + '       Inscr.Estadual:' + FormatIE( ::aEmit[ "IE" ], ::aEmit[ "UF" ] ), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )

   // box do nome do documento
   hbnfe_Box_hpdf( ::oPdfPage, 303, ::nLinhaPdf - 032, 145, 032, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 303, ::nLinhaPdf - 001, 448, Nil, "DACTE", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 12 )
   hbnfe_Texto_hpdf( ::oPdfPage, 303, ::nLinhaPdf - 010, 448, Nil, "Documento Auxiliar do", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 303, ::nLinhaPdf - 016, 448, Nil, "Conhecimento de Transporte", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 303, ::nLinhaPdf - 022, 448, Nil, "Eletr�nico", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )

   // box do modal
   hbnfe_Box_hpdf( ::oPdfPage, 453, ::nLinhaPdf - 032, 140, 032, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 453, ::nLinhaPdf - 001, 588, Nil, "MODAL", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 10 )
   hbnfe_Texto_hpdf( ::oPdfPage, 453, ::nLinhaPdf - 015, 588, Nil, aModal[ Val( ::aIde[ "modal" ] ) ], HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 12 )

   // box do modelo
   hbnfe_Box_hpdf( ::oPdfPage, 303, ::nLinhaPdf - 060, 035, 025, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 303, ::nLinhaPdf - 040, 338, Nil, "Modelo", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 303, ::nLinhaPdf - 047, 338, Nil, ::aIde[ "mod" ], HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 10 )

   // box da serie
   hbnfe_Box_hpdf( ::oPdfPage, 338, ::nLinhaPdf - 060, 035, 025, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 338, ::nLinhaPdf - 040, 373, Nil, "S�rie", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 338, ::nLinhaPdf - 047, 373, Nil, ::aIde[ "serie" ], HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 10 )

   // box do numero
   hbnfe_Box_hpdf( ::oPdfPage, 373, ::nLinhaPdf - 060, 060, 025, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 373, ::nLinhaPdf - 040, 433, Nil, "N�mero", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 373, ::nLinhaPdf - 047, 433, Nil, ::aIde[ "nCT" ], HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 10 )

   // box do fl
   hbnfe_Box_hpdf( ::oPdfPage, 433, ::nLinhaPdf - 060, 035, 025, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 433, ::nLinhaPdf - 040, 468, Nil, "FL", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 433, ::nLinhaPdf - 047, 468, Nil, "1/1", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 10 )

   // box do data e hora
   hbnfe_Box_hpdf( ::oPdfPage, 468, ::nLinhaPdf - 060, 125, 025, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 468, ::nLinhaPdf - 040, 588, Nil, "Data e Hora de Emiss�o", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 468, ::nLinhaPdf - 047, 588, Nil, SubStr( ::aIde[ "dhEmi" ], 9, 2 ) + "/" + SubStr( ::aIde[ "dhEmi" ], 6, 2 ) + "/" + SubStr( ::aIde[ "dhEmi" ], 1, 4 ) + ' ' + SubStr( ::aIde[ "dhEmi" ], 12 ), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 10 )

   // box do controle do fisco
   hbnfe_Box_hpdf( ::oPdfPage, 303, ::nLinhaPdf - 129, 290, 066, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 303, ::nLinhaPdf - 065, 588, Nil, "CONTROLE DO FISCO", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 09 )
#ifdef __XHARBOUR__
   hbnfe_Texto_hpdf( ::oPdfPage, 303, ::nLinhaPdf - 075, 588, Nil, hbnfe_Codifica_Code128c( ::cChave ), HPDF_TALIGN_CENTER, Nil, ::cFonteCode128F, 17 )
#else
   // aten��o - chute inicial
   hZebra := hb_zebra_create_code128( ::cChave, Nil )
   hbNFe_Zebra_Draw_Hpdf( hZebra, ::oPdfPage, 300, ::nLinhaPDF -110, 0.9, 30 )
#endif
   hbnfe_Texto_hpdf( ::oPdfPage, 303, ::nLinhaPdf - 110, 588, Nil, "Chave de acesso para consulta de autenticidade no site www.cte.fazenda.gov.br", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 303, ::nLinhaPdf - 119, 588, Nil, TRANSF( ::cChave, "@R 99.9999.99.999.999/9999-99-99-999-999.999.999-999.999.999-9" ), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 8 )

   // box do tipo do cte
   hbnfe_Box_hpdf( ::oPdfPage, 003, ::nLinhaPdf - 154, 060, 032, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 003, ::nLinhaPdf - 125, 060, Nil, "Tipo do CTe", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 003, ::nLinhaPdf - 135, 060, Nil, aTipoCte[ Val( ::aIde[ "tpCTe" ] ) + 1 ], HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 10 )

   // box do tipo do servico
   hbnfe_Box_hpdf( ::oPdfPage, 063, ::nLinhaPdf - 154, 070, 032, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 063, ::nLinhaPdf - 125, 133, Nil, "Tipo Servi�o", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 063, ::nLinhaPdf - 135, 133, Nil, aTipoServ[ Val( ::aIde[ "tpServ" ] ) + 1 ], HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 10 )

   // box do tipo do Tomador do Servico
   hbnfe_Box_hpdf( ::oPdfPage, 133, ::nLinhaPdf - 154, 070, 032, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 133, ::nLinhaPdf - 125, 203, Nil, "Tomador", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 133, ::nLinhaPdf - 135, 203, Nil, aTomador[ Val( ::aIde[ "toma" ] ) + 1 ], HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 10 )

   // box do tipo Forma de Pagamento
   hbnfe_Box_hpdf( ::oPdfPage, 203, ::nLinhaPdf - 154, 095, 032, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 203, ::nLinhaPdf - 125, 298, Nil, "Forma de Pagamento", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 203, ::nLinhaPdf - 135, 298, Nil, aPagto[ Val( ::aIde[ "forPag" ] ) + 1 ], HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 10 )
   // box do No. do Protocolo
   hbnfe_Box_hpdf( ::oPdfPage, 303, ::nLinhaPdf - 154, 165, 022, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 303, ::nLinhaPdf - 135, 468, Nil, "No. PROTOCOLO", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )
   IF ::aProtocolo[ "nProt" ] != Nil
      hbnfe_Texto_hpdf( ::oPdfPage, 303, ::nLinhaPdf - 143, 468, Nil, ::aProtocolo[ "nProt" ] + ' - ' + SubStr( ::aProtocolo[ "dhRecbto" ], 9, 2 ) + "/" + SubStr( ::aProtocolo[ "dhRecbto" ], 6, 2 ) + "/" + SubStr( ::aProtocolo[ "dhRecbto" ], 1, 4 ) + ' ' + SubStr( ::aProtocolo[ "dhRecbto" ], 12 ), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 9 )
   ENDIF

   // box da Insc. da Suframa
   hbnfe_Box_hpdf( ::oPdfPage, 468, ::nLinhaPdf - 154, 125, 022, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 468, ::nLinhaPdf - 135, 588, Nil, "INSC. SUFRAMA DO DEST.", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )
   // hbnfe_Texto_hpdf( ::oPdfPage, 468 , ::nLinhaPdf-145 , 568, Nil, ::aDest[ "ISUF" ] , HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 6 )
   hbnfe_Texto_hpdf( ::oPdfPage, 468, ::nLinhaPdf - 143, 588, Nil, 'xxxxx xxxxxxxxxxxxxxx', HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 9 )

   // box da Natureza da Prestacao
   hbnfe_Box_hpdf( ::oPdfPage, 003, ::nLinhaPdf - 179, 590, 022, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - 160, 588, Nil, "CFOP - Natureza da Presta��o", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - 168, 588, Nil, ::aIde[ "CFOP" ] + ' - ' + ::aIde[ "natOp" ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 8 )

   // Box da Origem da Presta��o
   hbnfe_Box_hpdf( ::oPdfPage,  003, ::nLinhaPdf - 204, 295, 022, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - 185, 295, Nil, "Origem da Presta��o", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - 193, 295, Nil, ::aIde[ "xMunIni" ] + ' - ' + ::aIde[ "UFIni" ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 8 )

   // Box do Destino da Presta��o
   hbnfe_Box_hpdf( ::oPdfPage,  303, ::nLinhaPdf - 204, 290, 022, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 308, ::nLinhaPdf - 185, 588, Nil, "Destino da Presta��o", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 308, ::nLinhaPdf - 193, 588, Nil, ::aIde[ "xMunFim" ] + ' - ' + ::aIde[ "UFFim" ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 8 )

   // Box do Remetente
   hbnfe_Box_hpdf( ::oPdfPage,  003, ::nLinhaPdf - 261, 295, 054, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - 207, 040, Nil, "Remetente ", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 042, ::nLinhaPdf - 208, 295, Nil, ::aRem[ "xNome" ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - 215, 040, Nil, "Endere�o", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 042, ::nLinhaPdf - 216, 295, Nil, ::aRem[ "xLgr" ] + " " + iif( ::aRem[ "nro" ]  != Nil, ::aRem[ "nro" ], '' ) + " " + iif( ::aRem[ "xCpl" ] != Nil, ::aRem[ "xCpl" ], '' ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   hbnfe_Texto_hpdf( ::oPdfPage, 042, ::nLinhaPdf - 224, 295, Nil, ::aRem[ "xBairro" ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - 232, 040, Nil, "Munic�pio", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 042, ::nLinhaPdf - 233, 240, Nil, ::aRem[ "xMun" ] + " " + ::aRem[ "UF" ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   hbnfe_Texto_hpdf( ::oPdfPage, 240, ::nLinhaPdf - 232, 260, Nil, "CEP", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 260, ::nLinhaPdf - 233, 295, Nil, SubStr( ::aRem[ "CEP" ], 1, 5 ) + '-' + SubStr( ::aRem[ "CEP" ], 6, 3 ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - 240, 042, Nil, "CNPJ/CPF", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   IF ! Empty( ::aRem[ "CNPJ" ] )
      hbnfe_Texto_hpdf( ::oPdfPage, 042, ::nLinhaPdf - 241, 150, Nil, Transform( ::aRem[ "CNPJ" ], "@R 99.999.999/9999-99" ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   ENDIF
   IF ! Empty( ::aRem[ "CPF" ] )
      hbnfe_Texto_hpdf( ::oPdfPage, 042, ::nLinhaPdf - 241, 150, Nil, Transform( ::aRem[ "CPF" ], "@R 999.999.999-99" ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   ENDIF
   hbnfe_Texto_hpdf( ::oPdfPage, 150, ::nLinhaPdf - 240, 250, Nil, "INSCRI��O ESTADUAL", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 245, ::nLinhaPdf - 241, 295, Nil, FormatIE( ::aRem[ "IE" ], ::aRem[ "UF" ] ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - 248, 042, Nil, "Pais", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 042, ::nLinhaPdf - 249, 150, Nil, ::aRem[ "xPais" ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   hbnfe_Texto_hpdf( ::oPdfPage, 225, ::nLinhaPdf - 248, 250, Nil, "FONE", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   If ::aRem[ "fone" ] != Nil
      hbnfe_Texto_hpdf( ::oPdfPage, 250, ::nLinhaPdf - 249, 295, Nil, TRANSF( Val( ::aRem[ "fone" ] ), "@R (99)9999-9999" ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   ENDIF

   // Box do Destinatario
   hbnfe_Box_hpdf( ::oPdfPage,  303, ::nLinhaPdf - 261, 290, 054, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 305, ::nLinhaPdf - 207, 340, Nil, "Destinat�rio", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 7 )
   hbnfe_Texto_hpdf( ::oPdfPage, 342, ::nLinhaPdf - 208, 595, Nil, ::aDest[ "xNome" ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   hbnfe_Texto_hpdf( ::oPdfPage, 305, ::nLinhaPdf - 215, 340, Nil, "Endere�o", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 342, ::nLinhaPdf - 216, 588, Nil, ::aDest[ "xLgr" ] + " " + iif( ::aDest[ "nro" ]  != Nil, ::aDest[ "nro" ], '' ) + " " + iif( ::aDest[ "xCpl" ] != Nil, ::aDest[ "xCpl" ], '' ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   hbnfe_Texto_hpdf( ::oPdfPage, 342, ::nLinhaPdf - 224, 588, Nil, ::aDest[ "xBairro" ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   hbnfe_Texto_hpdf( ::oPdfPage, 305, ::nLinhaPdf - 232, 340, Nil, "Munic�pio", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 342, ::nLinhaPdf - 233, 540, Nil, ::aDest[ "xMun" ] + " " + ::aDest[ "UF" ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   hbnfe_Texto_hpdf( ::oPdfPage, 535, ::nLinhaPdf - 232, 555, Nil, "CEP", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 555, ::nLinhaPdf - 233, 588, Nil, SubStr( ::aDest[ "CEP" ], 1, 5 ) + '-' + SubStr( ::aDest[ "CEP" ], 6, 3 ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   hbnfe_Texto_hpdf( ::oPdfPage, 305, ::nLinhaPdf - 240, 342, Nil, "CNPJ/CPF", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   IF ! Empty( ::aDest[ "CNPJ" ] )
      hbnfe_Texto_hpdf( ::oPdfPage, 342, ::nLinhaPdf - 241, 450, Nil, TRANS( ::aDest[ "CNPJ" ], "@R 99.999.999/9999-99" ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   ENDIF
   IF ! Empty( ::aDest[ "CPF" ] )
      hbnfe_Texto_hpdf( ::oPdfPage, 342, ::nLinhaPdf - 241, 450, Nil, TRANS( ::aDest[ "CPF" ], "@R 999.999.999-99" ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   ENDIF
   hbnfe_Texto_hpdf( ::oPdfPage, 430, ::nLinhaPdf - 240, 530, Nil, "INSCRI��O ESTADUAL", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )

   hbnfe_Texto_hpdf( ::oPdfPage, 530, ::nLinhaPdf - 241, 595, Nil, AllTrim( ::aDest[ "IE" ], ::aDest[ "UF" ] ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   hbnfe_Texto_hpdf( ::oPdfPage, 305, ::nLinhaPdf - 248, 342, Nil, "Pais", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 342, ::nLinhaPdf - 249, 450, Nil, ::aDest[ "xPais" ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   hbnfe_Texto_hpdf( ::oPdfPage, 520, ::nLinhaPdf - 248, 545, Nil, "FONE", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   IF ! Empty( ::aDest[ "fone" ] )
      hbnfe_Texto_hpdf( ::oPdfPage, 545, ::nLinhaPdf - 249, 595, Nil, '(' + SubStr( ::aDest[ "fone" ], 1, 2 ) + ')' + SubStr( ::aDest[ "fone" ], 3, 4 ) + '-' + SubStr( ::aDest[ "fone" ], 7, 4 ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   ENDIF
   // Box do Expedidor
   hbnfe_Box_hpdf( ::oPdfPage,  003, ::nLinhaPdf - 318, 295, 054, ::nLarguraBox )

   hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - 264, 040, Nil, "Expedidor", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   If ::aExped[ "xNome" ] != Nil
      hbnfe_Texto_hpdf( ::oPdfPage, 042, ::nLinhaPdf - 265, 295, Nil, ::aExped[ "xNome" ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   ENDIF
   hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - 272, 040, Nil, "Endere�o", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   If ::aExped[ "xLgr" ] != Nil
      hbnfe_Texto_hpdf( ::oPdfPage, 042, ::nLinhaPdf - 273, 295, Nil, ::aExped[ "xLgr" ] + " " + iif( ::aExped[ "nro" ]  != Nil, ::aExped[ "nro" ], '' ) + " " + iif( ::aExped[ "xCpl" ] != Nil, ::aExped[ "xCpl" ], '' ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   ENDIF
   If ::aExped[ "xBairro" ] != Nil
      hbnfe_Texto_hpdf( ::oPdfPage, 042, ::nLinhaPdf - 280, 295, Nil, ::aExped[ "xBairro" ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   ENDIF
   hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - 288, 040, Nil, "Munic�pio", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   If ::aExped[ "xMun" ] != Nil
      hbnfe_Texto_hpdf( ::oPdfPage, 042, ::nLinhaPdf - 289, 240, Nil, ::aExped[ "xMun" ] + " " + ::aExped[ "UF" ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   ENDIF
   hbnfe_Texto_hpdf( ::oPdfPage, 240, ::nLinhaPdf - 288, 260, Nil, "CEP", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   If ::aExped[ "CEP" ] != Nil
      hbnfe_Texto_hpdf( ::oPdfPage, 260, ::nLinhaPdf - 289, 295, Nil, SubStr( ::aExped[ "CEP" ], 1, 5 ) + '-' + SubStr( ::aExped[ "CEP" ], 6, 3 ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   ENDIF
   hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - 296, 042, Nil, "CNPJ/CPF", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   If ::aExped[ "CNPJ" ] != Nil
      hbnfe_Texto_hpdf( ::oPdfPage, 042, ::nLinhaPdf - 297, 150, Nil, TRANSF( ::aExped[ "CNPJ" ], "@R 99.999.999/9999-99" ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   ENDIF
   If ::aExped[ "CPF" ] != Nil
      hbnfe_Texto_hpdf( ::oPdfPage, 042, ::nLinhaPdf - 297, 150, Nil, TRANSF( ::aExped[ "CPF" ], "@R 999.999.999-99" ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   ENDIF
   hbnfe_Texto_hpdf( ::oPdfPage, 150, ::nLinhaPdf - 296, 250, Nil, "INSCRI��O ESTADUAL", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 245, ::nLinhaPdf - 297, 295, Nil, AllTrim( ::aExped[ "IE" ] ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - 304, 042, Nil, "Pais", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   If ::aExped[ "xPais" ] != Nil
      hbnfe_Texto_hpdf( ::oPdfPage, 042, ::nLinhaPdf - 305, 150, Nil, ::aExped[ "xPais" ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   ENDIF
   hbnfe_Texto_hpdf( ::oPdfPage, 225, ::nLinhaPdf - 304, 250, Nil, "FONE", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   If ::aExped[ "fone" ] != Nil
      hbnfe_Texto_hpdf( ::oPdfPage, 250, ::nLinhaPdf - 305, 295, Nil, '(' + SubStr( ::aExped[ "fone" ], 1, 2 ) + ')' + SubStr( ::aExped[ "fone" ], 3, 4 ) + '-' + SubStr( ::aExped[ "fone" ], 7, 4 ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   ENDIF

   // Box do Recebedor
   hbnfe_Box_hpdf( ::oPdfPage,  303, ::nLinhaPdf - 318, 290, 054, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 305, ::nLinhaPdf - 264, 340, Nil, "Recebedor", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 7 )
   If ::aReceb[ "xNome" ] != Nil
      hbnfe_Texto_hpdf( ::oPdfPage, 342, ::nLinhaPdf - 265, 595, Nil, ::aReceb[ "xNome" ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   ENDIF
   hbnfe_Texto_hpdf( ::oPdfPage, 305, ::nLinhaPdf - 272, 340, Nil, "Endere�o", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   If ::aReceb[ "xLgr" ] != Nil
      hbnfe_Texto_hpdf( ::oPdfPage, 342, ::nLinhaPdf - 273, 588, Nil, ::aReceb[ "xLgr" ] + " " + iif( ::aReceb[ "nro" ]  != Nil, ::aReceb[ "nro" ], '' ) + " " + iif( ::aReceb[ "xCpl" ] != Nil, ::aReceb[ "xCpl" ], '' ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   ENDIF
   If ::aReceb[ "xBairro" ] != Nil
      hbnfe_Texto_hpdf( ::oPdfPage, 342, ::nLinhaPdf - 280, 588, Nil, ::aReceb[ "xBairro" ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   ENDIF
   hbnfe_Texto_hpdf( ::oPdfPage, 305, ::nLinhaPdf - 288, 340, Nil, "Munic�pio", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   If ::aReceb[ "xMun" ] != Nil
      hbnfe_Texto_hpdf( ::oPdfPage, 342, ::nLinhaPdf - 289, 540, Nil, ::aReceb[ "xMun" ] + " " + ::aReceb[ "UF" ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   ENDIF
   hbnfe_Texto_hpdf( ::oPdfPage, 535, ::nLinhaPdf - 288, 555, Nil, "CEP", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   If ::aReceb[ "CEP" ] != Nil
      hbnfe_Texto_hpdf( ::oPdfPage, 555, ::nLinhaPdf - 289, 588, Nil, SubStr( ::aReceb[ "CEP" ], 1, 5 ) + '-' + SubStr( ::aReceb[ "CEP" ], 6, 3 ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   ENDIF
   hbnfe_Texto_hpdf( ::oPdfPage, 305, ::nLinhaPdf - 296, 342, Nil, "CNPJ/CPF", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   If ::aReceb[ "CNPJ" ] != Nil
      hbnfe_Texto_hpdf( ::oPdfPage, 342, ::nLinhaPdf - 297, 450, Nil, TRANSF( ::aReceb[ "CNPJ" ], "@R 99.999.999/9999-99" ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   ENDIF
   If ::aReceb[ "CPF" ] != Nil
      hbnfe_Texto_hpdf( ::oPdfPage, 342, ::nLinhaPdf - 297, 450, Nil, TRANSF( ::aReceb[ "CPF" ], "@R 999.999.999-99" ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   ENDIF
   hbnfe_Texto_hpdf( ::oPdfPage, 440, ::nLinhaPdf - 296, 540, Nil, "INSCRI��O ESTADUAL", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 540, ::nLinhaPdf - 297, 590, Nil, FormatIE( ::aReceb[ "IE" ], ::aReceb[ "UF" ] ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   hbnfe_Texto_hpdf( ::oPdfPage, 305, ::nLinhaPdf - 304, 342, Nil, "Pais", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   If ::aReceb[ "xPais" ] != Nil
      hbnfe_Texto_hpdf( ::oPdfPage, 342, ::nLinhaPdf - 305, 450, Nil, ::aReceb[ "xPais" ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   ENDIF
   hbnfe_Texto_hpdf( ::oPdfPage, 520, ::nLinhaPdf - 304, 545, Nil, "FONE", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   If ::aReceb[ "fone" ] != Nil
      hbnfe_Texto_hpdf( ::oPdfPage, 545, ::nLinhaPdf - 305, 595, Nil, '(' + SubStr( ::aReceb[ "fone" ], 1, 2 ) + ')' + SubStr( ::aReceb[ "fone" ], 3, 4 ) + '-' + SubStr( ::aReceb[ "fone" ], 7, 4 ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   ENDIF

   // Box do Tomador
   hbnfe_Box_hpdf( ::oPdfPage,  003, ::nLinhaPdf - 347, 590, 026, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - 321, 075, Nil, "Tomador do Servi�o", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 077, ::nLinhaPdf - 322, 330, Nil, ::aToma[ "xNome" ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   hbnfe_Texto_hpdf( ::oPdfPage, 337, ::nLinhaPdf - 321, 372, Nil, "Munic�pio", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 373, ::nLinhaPdf - 322, 460, Nil, ::aToma[ "xMun" ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   hbnfe_Texto_hpdf( ::oPdfPage, 495, ::nLinhaPdf - 321, 510, Nil, "UF", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 512, ::nLinhaPdf - 322, 534, Nil, ::aToma[ "UF" ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   hbnfe_Texto_hpdf( ::oPdfPage, 530, ::nLinhaPdf - 321, 550, Nil, "CEP", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 552, ::nLinhaPdf - 322, 590, Nil, SubStr( ::aToma[ "CEP" ], 1, 5 ) + '-' + SubStr( ::aToma[ "CEP" ], 6, 3 ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - 329, 040, Nil, "Endere�o", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 042, ::nLinhaPdf - 330, 590, Nil, ::aToma[ "xLgr" ] + " " + iif( ::aToma[ "nro" ]  != Nil, ::aToma[ "nro" ], '' ) + " " + iif( ::aToma[ "xCpl" ] != Nil, ::aToma[ "xCpl" ], '' ) + ' - ' + ::aToma[ "xBairro" ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - 337, 042, Nil, "CNPJ/CPF", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )

   IF ! Empty( ::aToma[ "CNPJ" ] )
      hbnfe_Texto_hpdf( ::oPdfPage, 042, ::nLinhaPdf - 338, 150, Nil, TRANSF( ::aToma[ "CNPJ" ], "@R 99.999.999/9999-99" ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   ENDIF
   IF ! Empty( ::aToma[ "CPF" ] )
      hbnfe_Texto_hpdf( ::oPdfPage, 042, ::nLinhaPdf - 338, 150, Nil, TRANSF( ::aToma[ "CPF" ], "@R 999.999.999-99" ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   ENDIF

   hbnfe_Texto_hpdf( ::oPdfPage, 150, ::nLinhaPdf - 337, 250, Nil, "INSCRI��O ESTADUAL", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 245, ::nLinhaPdf - 338, 295, Nil, FormatIE( ::aToma[ "IE" ], ::aToma[ "UF" ] ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   hbnfe_Texto_hpdf( ::oPdfPage, 425, ::nLinhaPdf - 337, 465, Nil, "Pais", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 442, ::nLinhaPdf - 338, 500, Nil, ::aToma[ "xPais" ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   hbnfe_Texto_hpdf( ::oPdfPage, 520, ::nLinhaPdf - 337, 560, Nil, "FONE", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   If ::aToma[ "fone" ] != Nil
      hbnfe_Texto_hpdf( ::oPdfPage, 542, ::nLinhaPdf - 338, 590, Nil, '(' + SubStr( ::aToma[ "fone" ], 1, 2 ) + ')' + SubStr( ::aToma[ "fone" ], 3, 4 ) + '-' + SubStr( ::aToma[ "fone" ], 7, 4 ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   ENDIF

   // Box do Produto Predominante
   hbnfe_Box_hpdf( ::oPdfPage,  003, ::nLinhaPdf - 373, 340, 023, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - 350, 150, Nil, "Produto Predominante", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - 360, 330, Nil, ::aInfCarga[ "proPred" ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 10 )
   hbnfe_Box_hpdf( ::oPdfPage,  343, ::nLinhaPdf - 373, 125, 023, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 348, ::nLinhaPdf - 350, 470, Nil, "Outras Caracter�sticas da Carga", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 348, ::nLinhaPdf - 360, 470, Nil, ::aInfCarga[ "xOutCat" ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 10 )
   hbnfe_Box_hpdf( ::oPdfPage,  468, ::nLinhaPdf - 373, 125, 023, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 473, ::nLinhaPdf - 350, 590, Nil, "Valot Total da Mercadoria", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 473, ::nLinhaPdf - 358, 580, Nil, Trans( Val( ::aInfCarga[ "vCarga" ] ), '@E 9,999,999.99' ), HPDF_TALIGN_RIGHT, Nil, ::oPdfFontCabecalhoBold, 12 )

   // Box das Quantidades
   hbnfe_Box_hpdf( ::oPdfPage,  003, ::nLinhaPdf - 398, 090, 025, ::nLarguraBox )
   hbnfe_Box_hpdf( ::oPdfPage,  093, ::nLinhaPdf - 398, 090, 025, ::nLarguraBox )
   hbnfe_Box_hpdf( ::oPdfPage,  183, ::nLinhaPdf - 398, 090, 025, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - 373, 090, Nil, "QT./UN./Medida", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   IF Len( ::aInfQ ) > 0
      hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - 383, 098, Nil, AllTrim( Tran( Val( ::aInfQ[ 1, 3 ] ), '@E 999,999.999' ) ) + '/' + aUnid[ Val( ::aInfQ[ 1, 1 ] ) + 1 ] + '/' + ::aInfQ[ 1, 2 ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   ENDIF
   hbnfe_Texto_hpdf( ::oPdfPage, 098, ::nLinhaPdf - 373, 190, Nil, "QT./UN./Medida", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   IF Len( ::aInfQ ) > 1
      hbnfe_Texto_hpdf( ::oPdfPage, 098, ::nLinhaPdf - 383, 188, Nil, AllTrim( Tran( Val( ::aInfQ[ 2, 3 ] ), '@E 999,999.999' ) ) + '/' + aUnid[ Val( ::aInfQ[ 2, 1 ] ) + 1 ] + '/' + ::aInfQ[ 2, 2 ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   ENDIF
   hbnfe_Texto_hpdf( ::oPdfPage, 188, ::nLinhaPdf - 373, 250, Nil, "QT./UN./Medida", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   IF Len( ::aInfQ ) > 2
      hbnfe_Texto_hpdf( ::oPdfPage, 188, ::nLinhaPdf - 383, 273, Nil, AllTrim( Tran( Val( ::aInfQ[ 3, 3 ] ), '@E 999,999.999' ) ) + '/' + aUnid[ Val( ::aInfQ[ 3, 1 ] ) + 1 ] + '/' + ::aInfQ[ 3, 2 ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   ENDIF

   // Box da Seguradora
   hbnfe_Box_hpdf( ::oPdfPage,  273, ::nLinhaPdf - 383, 320, 010, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 278, ::nLinhaPdf - 373, 400, Nil, "Nome da Seguradora", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 7 )
   hbnfe_Texto_hpdf( ::oPdfPage, 405, ::nLinhaPdf - 373, 580, Nil, ::aSeg[ "xSeg" ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   hbnfe_Box_hpdf( ::oPdfPage,  273, ::nLinhaPdf - 398, 097, 015, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 278, ::nLinhaPdf - 383, 370, Nil, "Respons�vel", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 7 )
   hbnfe_Texto_hpdf( ::oPdfPage, 278, ::nLinhaPdf - 389, 370, Nil, aResp[ Val( ::aSeg[ "respSeg" ] ) + 1 ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   hbnfe_Box_hpdf( ::oPdfPage,  370, ::nLinhaPdf - 398, 098, 015, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 375, ::nLinhaPdf - 383, 465, Nil, "N�mero da Ap�lice", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 7 )
   hbnfe_Texto_hpdf( ::oPdfPage, 375, ::nLinhaPdf - 389, 468, Nil, ::aSeg[ "nApol" ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )
   hbnfe_Box_hpdf( ::oPdfPage,  468, ::nLinhaPdf - 398, 125, 015, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 473, ::nLinhaPdf - 383, 590, Nil, "N�mero da Averba��o", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 7 )
   hbnfe_Texto_hpdf( ::oPdfPage, 473, ::nLinhaPdf - 389, 590, Nil, ::aSeg[ "nAver" ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 7 )

   // Box dos Componentes do Valor da Presta��o do Servi�o
   hbnfe_Box_hpdf( ::oPdfPage,  003, ::nLinhaPdf - 410, 590, 009, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 003, ::nLinhaPdf - 400, 590, Nil, "Componentes do Valor da Presta��o do Servi�o", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )
   // Box de Servicos e Valores
   hbnfe_Box_hpdf( ::oPdfPage,  003, ::nLinhaPdf - 475, 165, 062, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - 413, 085, Nil, "Nome", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 085, ::nLinhaPdf - 413, 165, Nil, "Valor", HPDF_TALIGN_RIGHT, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Box_hpdf( ::oPdfPage,  168, ::nLinhaPdf - 475, 165, 062, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 171, ::nLinhaPdf - 413, 251, Nil, "Nome", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 251, ::nLinhaPdf - 413, 330, Nil, "Valor", HPDF_TALIGN_RIGHT, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Box_hpdf( ::oPdfPage,  333, ::nLinhaPdf - 475, 165, 062, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 338, ::nLinhaPdf - 413, 418, Nil, "Nome", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 418, ::nLinhaPdf - 413, 495, Nil, "Valor", HPDF_TALIGN_RIGHT, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Box_hpdf( ::oPdfPage,  498, ::nLinhaPdf - 444, 095, 031, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 498, ::nLinhaPdf - 417, 590, Nil, "Valor Total do Servi�o", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 498, ::nLinhaPdf - 427, 580, Nil, Trans( Val( ::aPrest[ "vTPrest" ] ), '@E 999,999.99' ), HPDF_TALIGN_RIGHT, Nil, ::oPdfFontCabecalhoBold, 12 )
   hbnfe_Box_hpdf( ::oPdfPage,  498, ::nLinhaPdf - 475, 095, 031, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 498, ::nLinhaPdf - 447, 590, Nil, "Valor a Receber", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 498, ::nLinhaPdf - 457, 580, Nil, Trans( Val( ::aPrest[ "vRec" ] ), '@E 999,999.99' ), HPDF_TALIGN_RIGHT, Nil, ::oPdfFontCabecalhoBold, 12 )

   nLinha := 423
   FOR I = 1 TO Len( ::aComp ) STEP 3
      hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - nLinha, 165, Nil, ::aComp[ I, 1 ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 8 )
      hbnfe_Texto_hpdf( ::oPdfPage, 085, ::nLinhaPdf - nlinha, 165, Nil, Trans( Val( ::aComp[ I, 2 ] ), '@E 999,999.99' ), HPDF_TALIGN_RIGHT, Nil, ::oPdfFontCabecalhoBold, 8 )

      hbnfe_Texto_hpdf( ::oPdfPage, 171, ::nLinhaPdf - nLinha, 251, Nil, ::aComp[ I + 1,1 ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 8 )
      hbnfe_Texto_hpdf( ::oPdfPage, 251, ::nLinhaPdf - nLinha, 330, Nil, Trans( Val( ::aComp[ I + 1, 2 ] ), '@E 999,999.99' ), HPDF_TALIGN_RIGHT, Nil, ::oPdfFontCabecalhoBold, 8 )

      hbnfe_Texto_hpdf( ::oPdfPage, 338, ::nLinhaPdf - nLinha, 418, Nil, ::aComp[ I + 2,1 ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 8 )
      hbnfe_Texto_hpdf( ::oPdfPage, 418, ::nLinhaPdf - nLinha, 495, Nil, Trans( Val( ::aComp[ I + 2, 2 ] ), '@E 999,999.99' ), HPDF_TALIGN_RIGHT, Nil, ::oPdfFontCabecalhoBold, 8 )
      nLinha += 10
   NEXT

   // Box das Informa��es Relativas ao Imposto
   hbnfe_Box_hpdf( ::oPdfPage,  003, ::nLinhaPdf - 487, 590, 009, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 003, ::nLinhaPdf - 478, 590, Nil, "Informa��es Relativas ao Imposto", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )
   // Box da Situa��o Tribut�ria
   hbnfe_Box_hpdf( ::oPdfPage,  003, ::nLinhaPdf - 514, 155, 027, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - 488, 155, Nil, "Situa��o Tribut�ria", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   If ::aIcmsSN[ "indSN" ] != Nil
      hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - 500, 155, Nil, "SIMPLES NACIONAL", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 8 )
   ElseIf ::aIcms00[ "CST" ] != Nil
      hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - 500, 155, Nil, "00 - Tributa��o normal do ICMS", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 8 )
      nBase := ::aIcms00[ "vBC" ]
      nAliq := ::aIcms00[ "pICMS" ]
      nValor := ::aIcms00[ "vICMS" ]
      nReduc := ''
      nST := ''
   ElseIf ::aIcms20[ "CST" ] != Nil
      hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - 500, 155, Nil, "20 - Tributa��o com BC reduzida do ICMS", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 8 )
      nBase := ::aIcms20[ "vBC" ]
      nAliq := ::aIcms20[ "pICMS" ]
      nValor := ::aIcms20[ "vICMS" ]
      nReduc := ::aIcms20[ "pRedBC" ]
      nST := ''
   ElseIf ::aIcms45[ "CST" ] != Nil
      If ::aIcms45[ "CST" ] = '40'
         hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - 500, 155, Nil, "40 - ICMS isen��o", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 8 )
      ElseIf ::aIcms45[ "CST" ] = '41'
         hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - 500, 155, Nil, "41 - ICMS n�o tributada", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 8 )
      ElseIf ::aIcms45[ "CST" ] = '51'
         hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - 500, 155, Nil, "51 - ICMS diferido", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 8 )
      ENDIF
   ElseIf ::aIcms60[ "CST" ] != Nil
      hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - 500, 155, Nil, "60 - ICMS cobrado anteriormente por substitui��o tribut�ria", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 8 )
      nBase := ::aIcms60[ "vBCSTRet" ]
      nAliq := ::aIcms60[ "pICMSSTRet" ]
      nValor := ::aIcms60[ "vICMSSTRet" ]
      nReduc := ''
      nST := ::aIcms60[ "vCred" ]
   ElseIf ::aIcms90[ "CST" ] != Nil
      hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - 500, 155, Nil, "90 - ICMS Outros", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 8 )
      nBase := ::aIcms60[ "vBC" ]
      nAliq := ::aIcms60[ "pICMS" ]
      nValor := ::aIcms60[ "vICMS" ]
      nReduc := ::aIcms90[ "pRedBC" ]
      nST := ::aIcms60[ "vCred" ]
   ElseIf ::aIcmsUF[ "CST" ] != Nil
      hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - 500, 155, Nil, "90 - ICMS Outros", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 8 )
      nBase := ::aIcmsUF[ "vBCOutraUF" ]
      nAliq := ::aIcmsUF[ "pICMSOutraUF" ]
      nValor := ::aIcmsUF[ "vICMSOutraUF" ]
      nReduc := ::aIcmsUF[ "pRedBCOutraUF" ]
      nST := ''
   ELSE
      hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - 500, 155, Nil, "Sem Imposto de ICMS", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 8 )
   ENDIF

   // Box da Base De Calculo
   hbnfe_Box_hpdf( ::oPdfPage,  158, ::nLinhaPdf - 514, 080, 027, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 160, ::nLinhaPdf - 488, 238, Nil, "Base De Calculo", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 160, ::nLinhaPdf - 498, 238, Nil, Trans( Val( nBase ), '@E 999,999.99' ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 8 )
   // Box da Al�q ICMS
   hbnfe_Box_hpdf( ::oPdfPage,  238, ::nLinhaPdf - 514, 080, 027, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 240, ::nLinhaPdf - 488, 318, Nil, "Al�q ICMS", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 240, ::nLinhaPdf - 498, 318, Nil, Trans( Val( nAliq ), '@E 999,999.99' ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 8 )
   // Box do Valor ICMS
   hbnfe_Box_hpdf( ::oPdfPage,  318, ::nLinhaPdf - 514, 080, 027, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 320, ::nLinhaPdf - 488, 398, Nil, "Valor ICMS", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 320, ::nLinhaPdf - 498, 398, Nil, Trans( Val( nValor ), '@E 999,999.99' ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 8 )
   // Box da % Red. BC ICMS
   hbnfe_Box_hpdf( ::oPdfPage,  398, ::nLinhaPdf - 514, 080, 027, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 400, ::nLinhaPdf - 488, 478, Nil, "% Red. BC ICMS", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 400, ::nLinhaPdf - 498, 478, Nil, Trans( Val( nReduc ), '@E 999,999.99' ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 8 )
   // Box do ICMS ST
   hbnfe_Box_hpdf( ::oPdfPage,  478, ::nLinhaPdf - 514, 115, 027, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 480, ::nLinhaPdf - 488, 590, Nil, "ICMS ST", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 480, ::nLinhaPdf - 498, 590, Nil, Trans( Val( nSt ), '@E 999,999.99' ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 8 )

   // Box dos Documentos Origin�rios
   hbnfe_Box_hpdf( ::oPdfPage,  003, ::nLinhaPdf - 526, 590, 009, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 003, ::nLinhaPdf - 517, 590, Nil, "Documentos Origin�rios", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )
   // Box dos documentos a esquerda
   hbnfe_Box_hpdf( ::oPdfPage,  003, ::nLinhaPdf - 626, 295, 100, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - 526, 050, Nil, "Tipo DOC", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   IF Len( ::aInfNF ) > 0
      hbnfe_Texto_hpdf( ::oPdfPage, 050, ::nLinhaPdf - 526, 240, Nil, "CNPJ/CPF Emitente", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   ELSEIF Len( ::aInfOutros ) > 0
      hbnfe_Texto_hpdf( ::oPdfPage, 170, ::nLinhaPdf - 526, 240, Nil, "CNPJ/CPF Emitente", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   ELSEIF Len( ::aInfNFe ) > 0
      hbnfe_Texto_hpdf( ::oPdfPage, 050, ::nLinhaPdf - 526, 240, Nil, "CHAVE DE ACESSO DA NF-e", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   ELSE
      hbnfe_Texto_hpdf( ::oPdfPage, 050, ::nLinhaPdf - 526, 240, Nil, "CNPJ/CPF Emitente", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   ENDIF
   hbnfe_Texto_hpdf( ::oPdfPage, 240, ::nLinhaPdf - 526, 295, Nil, "S�rie/Nro. Doc.", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )

   // Box dos documentos a direita
   hbnfe_Box_hpdf( ::oPdfPage,  298, ::nLinhaPdf - 626, 295, 100, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 300, ::nLinhaPdf - 526, 345, Nil, "Tipo DOC", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   IF Len( ::aInfNF ) > 0
      hbnfe_Texto_hpdf( ::oPdfPage, 345, ::nLinhaPdf - 526, 535, Nil, "CNPJ/CPF Emitente", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   ELSEIF Len( ::aInfOutros ) > 0
      hbnfe_Texto_hpdf( ::oPdfPage, 465, ::nLinhaPdf - 526, 535, Nil, "CNPJ/CPF Emitente", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   ELSEIF Len( ::aInfNFe ) > 0
      hbnfe_Texto_hpdf( ::oPdfPage, 345, ::nLinhaPdf - 526, 535, Nil, "CHAVE DE ACESSO DA NF-e", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   ELSE
      hbnfe_Texto_hpdf( ::oPdfPage, 345, ::nLinhaPdf - 526, 535, Nil, "CNPJ/CPF Emitente", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   ENDIF
   hbnfe_Texto_hpdf( ::oPdfPage, 535, ::nLinhaPdf - 526, 590, Nil, "S�rie/Nro. Doc.", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )

   IF Len( ::aInfNFe ) > 0
      nLinha := 536
      FOR I = 1 TO Len( ::aInfNFe ) STEP 2
         IF ! Empty( ::aInfNFe[ I, 1 ] )
            hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - nLinha, 353, Nil, "NF-E", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
            hbnfe_Texto_hpdf( ::oPdfPage, 050, ::nLinhaPdf - nLinha, 240, Nil, ::aInfNFe[ I, 1 ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 8 )
            hbnfe_Texto_hpdf( ::oPdfPage, 240, ::nLinhaPdf - nLinha, 295, Nil, SubStr( ::aInfNFe[ I, 1 ], 23, 3 ) + '/' + SubStr( ::aInfNFe[ I, 1 ], 26, 9 ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 8 )
         ENDIF
         IF I + 1 <= Len( ::aInfNFe )
            hbnfe_Texto_hpdf( ::oPdfPage, 300, ::nLinhaPdf - nLinha, 353, Nil, "NF-E", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
            hbnfe_Texto_hpdf( ::oPdfPage, 345, ::nLinhaPdf - nLinha, 535, Nil, ::aInfNFe[ I + 1, 1 ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 8 )
            hbnfe_Texto_hpdf( ::oPdfPage, 535, ::nLinhaPdf - nLinha, 590, Nil, SubStr( ::aInfNFe[ I + 1, 1 ], 23, 3 ) + '/' + SubStr( ::aInfNFe[ I + 1, 1 ], 26, 9 ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 8 )
         ENDIF
         nLinha += 10
      NEXT
   ENDIF

   IF Len( ::aInfNF ) > 0
      nLinha := 536
      FOR I = 1 TO Len( ::aInfNF ) STEP 2
         IF !Empty( ::aInfNF[ I, 4 ] )
            hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - nLinha - 2, 353, Nil, "NOTA FISCAL", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 6 )
            IF Val( ::aRem[ "CNPJ" ] ) > 0
               hbnfe_Texto_hpdf( ::oPdfPage, 050, ::nLinhaPdf - nLinha, 240, Nil, TRANSF( ::aRem[ "CNPJ" ], "@R 99.999.999/9999-99" ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 8 )
            ENDIF
            IF Val( ::aRem[ "CPF" ] ) > 0
               hbnfe_Texto_hpdf( ::oPdfPage, 050, ::nLinhaPdf - nLinha, 240, Nil, TRANSF( ::aRem[ "CPF" ], "@R 999.999.999-99" ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 8 )
            ENDIF
            hbnfe_Texto_hpdf( ::oPdfPage, 240, ::nLinhaPdf - nLinha, 295, Nil, ::aInfNF[ I, 4 ] + '/' + ::aInfNF[ I, 5 ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 8 )
         ENDIF
         IF I + 1 <= Len( ::aINfNF )
            hbnfe_Texto_hpdf( ::oPdfPage, 300, ::nLinhaPdf - nLinha - 2, 353, Nil, "NOTA FISCAL", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 6 )
            IF Val( ::aRem[ "CNPJ" ] ) > 0
               hbnfe_Texto_hpdf( ::oPdfPage, 345, ::nLinhaPdf - nLinha, 535, Nil, TRANSF( ::aRem[ "CNPJ" ], "@R 99.999.999/9999-99" ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 8 )
            ENDIF
            IF Val( ::aRem[ "CPF" ] ) > 0
               hbnfe_Texto_hpdf( ::oPdfPage, 345, ::nLinhaPdf - nLinha, 535, Nil, TRANSF( ::aRem[ "CPF" ], "@R 999.999.999-99" ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 8 )
            ENDIF
            hbnfe_Texto_hpdf( ::oPdfPage, 535, ::nLinhaPdf - nLinha, 590, Nil, ::aInfNF[ I + 1, 4 ] + '/' + ::aInfNF[ I + 1, 5 ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 8 )
         ENDIF
         nLinha += 10
      NEXT
   ENDIF
   IF Len( ::aInfOutros ) > 0
      nLinha := 536
      FOR I = 1 TO Len( ::aInfOutros ) STEP 2
         If ::aInfOutros[ I, 1 ] = '00'
            cOutros := 'DECLARA��O'
         ElseIf ::aInfOutros[ I, 1 ] = '10'
            cOutros := 'DUTOVI�RIO'
         ElseIf ::aInfOutros[ I, 1 ] = '99'
            cOutros := ::aInfOutros[ I, 2 ]
         ENDIF
         hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - nLinha, 240, Nil, cOutros, HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 6 )
         IF Val( ::aRem[ "CNPJ" ] ) > 0
            hbnfe_Texto_hpdf( ::oPdfPage, 170, ::nLinhaPdf - nLinha, 240, Nil, TRANSF( ::aRem[ "CNPJ" ], "@R 99.999.999/9999-99" ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 8 )
         ENDIF
         IF Val( ::aRem[ "CPF" ] ) > 0
            hbnfe_Texto_hpdf( ::oPdfPage, 170, ::nLinhaPdf - nLinha, 240, Nil, TRANSF( ::aRem[ "CPF" ], "@R 999.999.999-99" ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 8 )
         ENDIF
         hbnfe_Texto_hpdf( ::oPdfPage, 240, ::nLinhaPdf - nLinha, 295, Nil, ::aInfOutros[ I, 3 ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 8 )
         IF I + 1 <= Len( ::aInfOutros )
            If ::aInfOutros[ I + 1, 1 ] = '00'
               cOutros := 'DECLARA��O'
            ElseIf ::aInfOutros[ I + 1, 1 ] = '10'
               cOutros := 'DUTOVI�RIO'
            ElseIf ::aInfOutros[ I + 1, 1 ] = '99'
               cOutros := ::aInfOutros[ I + 1, 2 ]
            ENDIF
            hbnfe_Texto_hpdf( ::oPdfPage, 300, ::nLinhaPdf - nLinha, 535, Nil, cOutros, HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 6 )
            IF Val( ::aRem[ "CNPJ" ] ) > 0
               hbnfe_Texto_hpdf( ::oPdfPage, 465, ::nLinhaPdf - nLinha, 535, Nil, TRANSF( ::aRem[ "CNPJ" ], "@R 99.999.999/9999-99" ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 8 )
            ENDIF
            IF Val( ::aRem[ "CPF" ] ) > 0
               hbnfe_Texto_hpdf( ::oPdfPage, 465, ::nLinhaPdf - nLinha, 535, Nil, TRANSF( ::aRem[ "CPF" ], "@R 999.999.999-99" ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 8 )
            ENDIF
            hbnfe_Texto_hpdf( ::oPdfPage, 535, ::nLinhaPdf - nLinha, 590, Nil, ::aInfOutros[ I + 1, 3 ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 8 )
         ENDIF
         nLinha += 10
      NEXT
   ENDIF

   // Box das Observa��es Gerais
   hbnfe_Box_hpdf( ::oPdfPage,  003, ::nLinhaPdf - 638, 590, 009, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 003, ::nLinhaPdf - 629, 590, Nil, "Observa��es Gerais", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Box_hpdf( ::oPdfPage,  003, ::nLinhaPdf - 668, 590, 030, ::nLarguraBox )
   /*
   ::aCompl[ "xObs" ]:=Upper('Este documento tem por objetivo a defini��o das especifica��es e crit�rios t�cnicos necess�rios' +;
   ' para a integra��o entre os Portais das Secretarias de Fazendas dos Estados e os sistemas de' +;
   ' informa��es das empresas emissoras de Conhecimento de Transporte eletr�nico - CT-e.')
   */
   IF ! Empty( ::aCompl[ "xObs" ] )
      AAdd( aObserv, ::aCompl[ "xObs" ] )
   ENDIF
   IF ! Empty( ::cAdFisco )
      AAdd( aObserv, ::cAdFisco )
   ENDIF
   If ::alocEnt[ 'xNome' ] != Nil
      cEntrega := 'Local de Entrega : '
      If ::alocEnt[ "CNPJ" ] != Nil
         cEntrega += 'CNPJ:' + ::alocEnt[ "CNPJ" ]
      ENDIF
      If ::alocEnt[ "CNPJ" ] != Nil
         cEntrega += 'CPF:' + ::alocEnt[ "CPF" ]
      ENDIF
      If ::alocEnt[ "xNome" ] != Nil
         cEntrega += ' - ' + ::alocEnt[ "xNome" ]
      ENDIF
      If ::alocEnt[ "xLgr" ] != Nil
         cEntrega += ' - ' + ::alocEnt[ "xLgr" ]
      ENDIF
      If ::alocEnt[ "nro" ] != Nil
         cEntrega += ',' + ::alocEnt[ "nro" ]
      ENDIF
      If ::alocEnt[ "xCpl" ] != Nil
         cEntrega += ::alocEnt[ "xCpl" ]
      ENDIF
      If ::alocEnt[ "xBairro" ] != Nil
         cEntrega += ::alocEnt[ "xBairro" ]
      ENDIF
      If ::alocEnt[ "xMun" ] != Nil
         cEntrega += ::alocEnt[ "xMun" ]
      ENDIF
      If ::alocEnt[ "UF" ] != Nil
         cEntrega += ::alocEnt[ "UF" ]
      ENDIF
      AAdd( aObserv, cEntrega )
   ENDIF
   nLinha := 638
   FOR EACH oElement IN aObserv
      DO WHILE Len( oElement ) > 0
         hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - nLinha, 590, Nil, Pad( oElement, 120 ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 8 )
         oElement := SubStr( oElement, 121 )
         nLinha += 10
      ENDDO
   NEXT
   /*
   If ::vTotTrib != Nil
    hbnfe_Texto_hpdf( ::oPdfPage, 005 , ::nLinhaPdf-675 , 590, Nil, 'Valor aproximado total de tributos federais, estaduais e municipais conf. Disposto na Lei n� 12741/12 : R$ '+Alltrim(Trans( Val(::vTotTrib) , '@E 999,999.99' )) , HPDF_TALIGN_LEFT , Nil, ::oPdfFontCabecalhoBold, 8 )
   Endif
   */
   // Box dos DADOS ESPEC�FICOS DO MODAL RODOVI�RIO - CARGA FRACIONADA
   hbnfe_Box_hpdf( ::oPdfPage,  003, ::nLinhaPdf - 680, 590, 009, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 003, ::nLinhaPdf - 671, 590, Nil, "DADOS ESPEC�FICOS DO MODAL RODOVI�RIO - CARGA FRACIONADA", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )
   // Box do RNTRC Da Empresa
   hbnfe_Box_hpdf( ::oPdfPage,  003, ::nLinhaPdf - 698, 140, 018, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - 680, 143, Nil, "RNTRC Da Empresa", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - 688, 143, Nil, ::aRodo[ "RNTRC" ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 8 )
   // Box do CIOT
   hbnfe_Box_hpdf( ::oPdfPage,  143, ::nLinhaPdf - 698, 070, 018, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 145, ::nLinhaPdf - 680, 213, Nil, "CIOT", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 145, ::nLinhaPdf - 688, 213, Nil, ::aRodo[ "CIOT" ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 8 )
   // Box do Lota��o
   hbnfe_Box_hpdf( ::oPdfPage,  213, ::nLinhaPdf - 698, 030, 018, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 215, ::nLinhaPdf - 680, 243, Nil, "Lota��o", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 215, ::nLinhaPdf - 688, 243, Nil, iif( Val( ::aRodo[ "lota" ] ) = 0, 'N�o', 'Sim' ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 8 )
   // Box do Data Prevista de Entrega
   hbnfe_Box_hpdf( ::oPdfPage,  243, ::nLinhaPdf - 698, 115, 018, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 245, ::nLinhaPdf - 680, 358, Nil, "Data Prevista de Entrega", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 245, ::nLinhaPdf - 688, 358, Nil, SubStr( ::aRodo[ "dPrev" ], 9, 2 ) + "/" + SubStr( ::aRodo[ "dPrev" ], 6, 2 ) + "/" + SubStr( ::aRodo[ "dPrev" ], 1, 4 ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 8 )
   // Box da Legisla��o
   hbnfe_Box_hpdf( ::oPdfPage,  358, ::nLinhaPdf - 698, 235, 018, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 360, ::nLinhaPdf - 680, 590, Nil, "ESTE CONHECIMENTO DE TRANSPORTE ATENDE", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 360, ::nLinhaPdf - 688, 590, Nil, "� LEGISLA��O DE TRANSPORTE RODOVI�RIO EM VIGOR", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )

   // Box da IDENTIFICA��O DO CONJUNTO TRANSPORTADOR
   hbnfe_Box_hpdf( ::oPdfPage,  003, ::nLinhaPdf - 706, 260, 008, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 003, ::nLinhaPdf - 698, 260, Nil, "IDENTIFICA��O DO CONJUNTO TRANSPORTADOR", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 6 )
   // Box das INFORMA��ES RELATIVAS AO VALE PED�GIO
   hbnfe_Box_hpdf( ::oPdfPage,  263, ::nLinhaPdf - 706, 330, 008, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 263, ::nLinhaPdf - 698, 590, Nil, "INFORMA��ES RELATIVAS AO VALE PED�GIO", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 6 )

   // Box do Tipo
   hbnfe_Box_hpdf( ::oPdfPage,  003, ::nLinhaPdf - 714, 055, 008, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - 707, 055, Nil, "TIPO", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 6 )
   // Box do PLACA
   hbnfe_Box_hpdf( ::oPdfPage,  058, ::nLinhaPdf - 714, 055, 008, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 060, ::nLinhaPdf - 707, 115, Nil, "PLACA", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 6 )
   // Box da UF
   hbnfe_Box_hpdf( ::oPdfPage,  113, ::nLinhaPdf - 714, 020, 008, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 115, ::nLinhaPdf - 707, 133, Nil, "UF", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 6 )
   // Box da RNTRC
   hbnfe_Box_hpdf( ::oPdfPage,  133, ::nLinhaPdf - 714, 130, 008, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 135, ::nLinhaPdf - 707, 260, Nil, "RNTRC", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 6 )
   // Box dos Dados acima
   hbnfe_Box_hpdf( ::oPdfPage,  003, ::nLinhaPdf - 736, 260, 022, ::nLarguraBox )
   nLinha := 714
   FOR I = 1 TO Len( ::aVeiculo )
      hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - nLinha, 055, Nil, aTipoCar[ Val( ::aVeiculo[ I, 10 ] ) + 1 ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 6 )
      hbnfe_Texto_hpdf( ::oPdfPage, 060, ::nLinhaPdf - nlinha, 115, Nil, ::aVeiculo[ I, 03 ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 6 )
      hbnfe_Texto_hpdf( ::oPdfPage, 115, ::nLinhaPdf - nlinha, 133, Nil, ::aVeiculo[ I, 11 ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 6 )
      hbnfe_Texto_hpdf( ::oPdfPage, 135, ::nLinhaPdf - nlinha, 260, Nil, ::aProp[ "RNTRC" ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 6 )
      hbnfe_Texto_hpdf( ::oPdfPage, 135, ::nLinhaPdf - nlinha, 260, Nil, ::aRodo[ "RNTRC" ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 6 )
      nLinha += 05
   NEXT

   // Box do CNPJ EMPRESA FORNECEDORA
   hbnfe_Box_hpdf( ::oPdfPage,  263, ::nLinhaPdf - 736, 110, 030, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 265, ::nLinhaPdf - 707, 373, Nil, "CNPJ EMPRESA FORNECEDORA", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 6 )
   hbnfe_Texto_hpdf( ::oPdfPage, 265, ::nLinhaPdf - 717, 373, Nil, ::aValePed[ "CNPJForn" ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 8 )
   // Box do CNPJ EMPRESA FORNECEDORA
   hbnfe_Box_hpdf( ::oPdfPage,  373, ::nLinhaPdf - 736, 110, 030, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 375, ::nLinhaPdf - 707, 483, Nil, "N�MERO DO COMPROVANTE", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 6 )
   hbnfe_Texto_hpdf( ::oPdfPage, 375, ::nLinhaPdf - 717, 483, Nil, ::aValePed[ "nCompra" ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 8 )
   // Box do CNPJ RESPONSAVEL PAGAMENTO
   hbnfe_Box_hpdf( ::oPdfPage,  483, ::nLinhaPdf - 736, 110, 030, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 485, ::nLinhaPdf - 707, 590, Nil, "CNPJ RESPONSAVEL PAGAMENTO", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 6 )
   hbnfe_Texto_hpdf( ::oPdfPage, 375, ::nLinhaPdf - 717, 483, Nil, ::aValePed[ "CNPJPg" ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 8 )
   // Box do Nome do Motorista
   hbnfe_Box_hpdf( ::oPdfPage,  003, ::nLinhaPdf - 744, 260, 008, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - 737, 050, Nil, "MOTORISTA:", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 6 )
   hbnfe_Texto_hpdf( ::oPdfPage, 060, ::nLinhaPdf - 737, 260, Nil, ::aMoto[ "xNome" ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 6 )
   // Box do CPF do Motorista
   hbnfe_Box_hpdf( ::oPdfPage, 263, ::nLinhaPdf - 744, 120, 008, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 265, ::nLinhaPdf - 737, 325, Nil, "CPF MOTORISTA:", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 6 )
   hbnfe_Texto_hpdf( ::oPdfPage, 330, ::nLinhaPdf - 737, 383, Nil, TRANS( ::aMoto[ "CPF" ], "@R 999.999.999-99" ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 6 )
   // Box do IDENT. LACRE EM TRANSP:
   hbnfe_Box_hpdf( ::oPdfPage, 383, ::nLinhaPdf - 744, 210, 008, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 385, ::nLinhaPdf - 737, 495, Nil, "IDENT. LACRE EM TRANSP.", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 6 )
   hbnfe_Texto_hpdf( ::oPdfPage, 500, ::nLinhaPdf - 737, 590, Nil, ::aRodo[ "nLacre" ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 6 )
   // Box do USO EXCLUSIVO DO EMISSOR DO CT-E
   hbnfe_Box_hpdf( ::oPdfPage,  003, ::nLinhaPdf - 752, 380, 008, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - 745, 385, Nil, "USO EXCLUSIVO DO EMISSOR DO CT-E", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 6 )
   hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - 753, 385, Nil, ::aObsCont[ "xTexto" ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 8 )
   // Box do RESERVADO AO FISCO
   hbnfe_Box_hpdf( ::oPdfPage,  383, ::nLinhaPdf - 752, 210, 008, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 385, ::nLinhaPdf - 745, 495, Nil, "RESERVADO AO FISCO", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 6 )

   hbnfe_Box_hpdf( ::oPdfPage,  003, ::nLinhaPdf - 762, 380, 010, ::nLarguraBox )
   hbnfe_Box_hpdf( ::oPdfPage,  383, ::nLinhaPdf - 762, 210, 010, ::nLarguraBox )
   // Data e Desenvolvedor da Impressao
   hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - 763, 200, NIL, "DATA E HORA DA IMPRESS�O : " + DToC( Date() ) + ' - ' + Time(), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 4 )
   hbnfe_Texto_hpdf( ::oPdfPage, 500, ::nLinhaPdf - 763, 593, NIL, "VesSystem", HPDF_TALIGN_RIGHT, Nil, ::oPdfFontCabecalhoBold, 4 )
   // linha tracejada
   HPDF_Page_SetDash( ::oPdfPage, DASH_MODE3, 4, 0 )
   HPDF_Page_SetLineWidth( ::oPdfPage, 0.5 )
   HPDF_Page_MoveTo( ::oPdfPage, 003, ::nLinhaPdf - 769 )
   HPDF_Page_LineTo( ::oPdfPage, 595, ::nLinhaPdf - 769 )
   HPDF_Page_Stroke( ::oPdfPage )
   HPDF_Page_SetDash( ::oPdfPage, NIL, 0, 0 )

   cMensa := 'DECLARO QUE RECEBI OS VOLUMES DESTE CONHECIMENTO EM PERFEITO ESTADO PELO QUE DOU POR CUMPRIDO O PRESENTE CONTRATO DE TRANSPORTE'
   hbnfe_Box_hpdf( ::oPdfPage,  003, ::nLinhaPdf - 782, 590, 009, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 003, ::nLinhaPdf - 773, 590, Nil, cMensa, HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 7 )
   // Box do Nome
   hbnfe_Box_hpdf( ::oPdfPage,  003, ::nLinhaPdf - 807, 160, 025, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - 782, 163, Nil, "Nome", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   // Box do RG
   hbnfe_Box_hpdf( ::oPdfPage,  003, ::nLinhaPdf - 832, 160, 025, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 005, ::nLinhaPdf - 807, 163, Nil, "RG", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 8 )
   // Box da ASSINATURA / CARIMBO
   hbnfe_Box_hpdf( ::oPdfPage,  163, ::nLinhaPdf - 832, 160, 050, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 165, ::nLinhaPdf - 822, 323, Nil, "ASSINATURA / CARIMBO", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )
   // Box da CHEGADA DATA/HORA
   hbnfe_Box_hpdf( ::oPdfPage,  323, ::nLinhaPdf - 807, 120, 025, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 325, ::nLinhaPdf - 782, 443, Nil, "CHEGADA DATA/HORA", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 6 )
   // Box da SA�DA DATA/HORA
   hbnfe_Box_hpdf( ::oPdfPage,  323, ::nLinhaPdf - 832, 120, 025, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 325, ::nLinhaPdf - 807, 443, Nil, "SA�DA DATA/HORA", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 6 )
   // Box do N�mero da CTe / S�rie
   hbnfe_Box_hpdf( ::oPdfPage,  443, ::nLinhaPdf - 807, 150, 025, ::nLarguraBox )
   hbnfe_Texto_hpdf( ::oPdfPage, 445, ::nLinhaPdf - 782, 593, Nil, "N�mero da CTe / S�rie", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )
   hbnfe_Texto_hpdf( ::oPdfPage, 445, ::nLinhaPdf - 792, 593, Nil, ::aIde[ "nCT" ] + ' / ' + ::aIde[ "serie" ], HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 10 )
   // Box do nome do emitente
   hbnfe_Box_hpdf( ::oPdfPage,  443, ::nLinhaPdf - 832, 150, 025, ::nLarguraBox )
   // Razao Social do Emitente
   IF Len( ::aEmit[ "xNome" ] ) <= 40
      hbnfe_Texto_hpdf( ::oPdfPage, 445, ::nLinhaPdf - 813, 593, Nil, SubStr( ::aEmit[ "xNome" ], 1, 20 ), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 8 )
      hbnfe_Texto_hpdf( ::oPdfPage, 445, ::nLinhaPdf - 820, 593, Nil, SubStr( ::aEmit[ "xNome" ], 21, 20 ), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 8 )
   ELSE
      hbnfe_Texto_hpdf( ::oPdfPage, 445, ::nLinhaPdf - 808, 593, Nil, SubStr( ::aEmit[ "xNome" ], 1, 30 ), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 6 )
      hbnfe_Texto_hpdf( ::oPdfPage, 445, ::nLinhaPdf - 815, 593, Nil, SubStr( ::aEmit[ "xNome" ], 31, 30 ), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 6 )
      hbnfe_Texto_hpdf( ::oPdfPage, 445, ::nLinhaPdf - 822, 593, Nil, SubStr( ::aEmit[ "xNome" ], 61, 30 ), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 6 )
   ENDIF

   RETURN NIL

STATIC FUNCTION FormatIE( cIE, cUF )

   cIE := AllTrim( cIE )
   IF cIE == "ISENTO" .OR. Empty( cIE )
      RETURN cIE
   ENDIF
   cIE := SoNumeros( cIE )

   HB_SYMBOL_UNUSED( cUF )

   RETURN cIE
