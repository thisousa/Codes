*****************************************************************************
* Projeto: STJ - Superior Tribunal de Justiça
* GAP/Interface: ER03 GAP010
* Programa: YERC0001
* Objetivo do programa: Programa de Carga Concurso Público, Cadastro de candidatos
* no E-recruiting.
* Desenvolvedor: Thiago Ramos de Sousa
* Data Criação: 25/09/2015
*****************************************************************************
* Histórico de Mudanças
*----------------------------------------------------------------------*
* Num.  Data         Autor          Request      Descrição             *
*----------------------------------------------------------------------*
*                                                                      *
*----------------------------------------------------------------------*
*****************************************************************************

REPORT yerc0001.

*----------------------------------------------------------------------*
* TIPOS                                                                *
*----------------------------------------------------------------------*
TYPES: BEGIN OF y_excel, "Estrutura da Tabela que Receberá o Arquivo
         codevent   TYPE char5,
         nivescng   TYPE char1,
         semestng   TYPE char1,
         cursoeng   TYPE char20,
         descridg   TYPE char255,
         codigodg   TYPE char8,
         nminccdt   TYPE hrp5200-zznumero_inscricao, "carregar via função
         nomecdt    TYPE char80,                     "assign_new_user-p_alias
         cpf        TYPE hrp5202-cpfnr,              "carregar via função
         identcdt   TYPE hrp5202-ident,              "carregar via função
         dtnascdt   TYPE char10, "but000-birthdt,    "carregar via função
         endeletr   TYPE hrp5102-e_mail,             "assign_new_user-p_email
         telcdt     TYPE adtel-tel_number,           "carregar via função
         endcdt     TYPE addr2_data-street,          "carregar via função
         coendcdt   TYPE addr2_data-street,          "carregar via função
         nmendcdt   TYPE addr2_data-house_num1,      "carregar via função
         bairrcdt   TYPE addr2_data-str_suppl3,      "carregar via função
         cidadcdt   TYPE addr2_data-city1,           "carregar via função
         sigufcdt   TYPE addr2_data-region,          "carregar via função
         cepcdt     TYPE addr2_data-post_code1,      "carregar via função
         cdtptnec   TYPE hrp5202-sbgru,              "carregar via função
         cdtdnegr   TYPE hrp5202-race,               "carregar via função
         notprobj   TYPE hrp5200-zznota_pocg,        "carregar via função
         notprobje  TYPE hrp5200-zznota_poce,        "carregar via função
         notfiprb   TYPE hrp5200-zznota_fpo,         "carregar via função
         stcdtprb   TYPE hrp5200-zzsituacao_cpo,     "carregar via função
         clcdtprb   TYPE hrp5200-zzsituacao_cpo,     "carregar via função
         clcdtprbde TYPE hrp5200-zzclassificacao_cpod, "carregar via função
         clcdtprbne TYPE hrp5200-zzclassificacao_fc_cn, "carregar via função
         ntprvdis   TYPE hrp5200-zznota_pd,            "carregar via função
         stcdtprdi  TYPE hrp5200-zzsituacao_cpd,       "carregar via função
         clafncdt   TYPE hrp5200-zzclassificacao_fc,   "carregar via função
         clafncdtd  TYPE hrp5200-zzclassificacao_fc_d, "carregar via função
         clafncdtn  TYPE hrp5200-zzclassificacao_fc_cn, "carregar via função
         incdtsubj  TYPE hrp5200-zzindicacao_cc_sj,     "carregar via função
         tipfamili  TYPE hrp5202-zztipo_de_familiar01, "carregar via função
         filiacao   TYPE hrp5202-zzfiliacao01,         "carregar via função
       END OF y_excel,

       BEGIN OF y_f4header, "Estrutura do Match Code do Campo Requisição
         objid  TYPE hrp5125-objid,
         header TYPE hrp5125-header,
       END OF   y_f4header,

       BEGIN OF y_return,
         type       TYPE bapiret2-type,
         id         TYPE bapiret2-id,
         number     TYPE bapiret2-number,
         message    TYPE bapiret2-message,
         log_no     TYPE bapiret2-log_no,
         log_msg_no TYPE bapiret2-log_msg_no,
         message_v1 TYPE bapiret2-message_v1,
       END OF y_return.


*----------------------------------------------------------------------*
* TABELAS INTERNAS                                                     *
*----------------------------------------------------------------------*
DATA: t_f4header      TYPE STANDARD TABLE OF  y_f4header,
      t_data          TYPE STANDARD TABLE OF  y_excel,
      t_dados         TYPE STANDARD TABLE OF  y_excel,
      t_yeryt0001     TYPE STANDARD TABLE OF  yeryt0001,
      t_raw           TYPE truxs_t_text_data,
      t_return        TYPE TABLE OF y_return,
      t_current_addr  TYPE rcf_t_addressdata_bp,
      t_current_telef TYPE rcf_t_telefondata_bp,
      t_current_email TYPE rcf_t_emaildata_bp,
      t_cand_cdcy     TYPE rcf_t_cand_cdcy,
      lo_5200         TYPE REF TO cl_hrpad_brpbs_iftyp5200.

*----------------------------------------------------------------------*
* VARIAVEIS / Work Areas                                               *
*----------------------------------------------------------------------*
DATA: vg_data(100) TYPE c,
      vg_plvar     TYPE plvar,
      vg_delim     TYPE c VALUE cl_abap_char_utilities=>horizontal_tab,
      vg_erro(1)   TYPE c VALUE 'E',
      vg_sucs(01)  TYPE c VALUE 'S'.

DATA: wa_result       TYPE char50.
DATA: wa_req_hrobject TYPE hrobject.
DATA: wa_data      TYPE y_excel,
      wa_dados     TYPE y_excel,
      wa_yeryt0001 TYPE yeryt0001.

DATA: wa_salv_table TYPE REF TO cl_salv_table,
      wa_columns    TYPE REF TO cl_salv_columns_table.
*----------------------------------------------------------------------*
* CONSTANTES                                                           *
*----------------------------------------------------------------------*
DATA: c_enab(4) TYPE c VALUE 'ENAB',
      c_x(1)    TYPE c VALUE 'X',
      c_sy      TYPE symsgid  VALUE 'SY',
      c_002     TYPE symsgno  VALUE '002',
      c_01(02)  TYPE n        VALUE '01',
      c_02(02)  TYPE n        VALUE '02',
      c_endda   TYPE char08   VALUE '99991231',
      c_5200    TYPE char04   VALUE '5200',
      c_mae     TYPE c        VALUE 'M',
      c_pai     TYPE c        VALUE 'P'.
*----------------------------------------------------------------------*
* Objetos globais
*----------------------------------------------------------------------*
DATA:
  og_ex   TYPE REF TO cx_hrrcf,
  og_bupa TYPE REF TO cl_hrrcf_candidate_bupa_bl.


DATA: og_candidate TYPE REF TO cl_hrrcf_candidate.
DATA: lo_candidacy TYPE REF TO cl_hrrcf_candidacy.

*----------------------------------------------------------------------*
* Field-Symbols
*----------------------------------------------------------------------*
FIELD-SYMBOLS: <fs_dados> TYPE y_excel.

*----------------------------------------------------------------------*
* TELA DE SELEÇÃO                                                      *
*----------------------------------------------------------------------*

SELECTION-SCREEN BEGIN OF BLOCK b00 WITH FRAME TITLE text-000.

PARAMETERS: p_header TYPE hrp5125-objid.

SELECTION-SCREEN SKIP.
SELECTION-SCREEN BEGIN OF BLOCK b01 WITH FRAME TITLE text-001.

PARAMETERS: p_file LIKE rlgrap-filename.
SELECTION-SCREEN END OF BLOCK b01.

SELECTION-SCREEN END OF BLOCK b00.

*----------------------------------------------------------------------*
* ÁREA DE PROCESSAMENTO DE TELA                                        *
*----------------------------------------------------------------------*
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_header.
*---> Obtem Match-Code do campo Requisição
  PERFORM z_header_f4help.

AT SELECTION-SCREEN.

  IF sy-ucomm NE c_enab.
    PERFORM z_check_requisicao.
  ENDIF.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.
*  IF p_locl EQ 'X'.
*---> Abre pop-up para busca do arquivo CSV
  PERFORM z_buscafile CHANGING p_file.
*  ENDIF.

*----------------------------------------------------------------------*
* ÁREA PARA SELEÇÃO                                                    *
*----------------------------------------------------------------------*
START-OF-SELECTION.

* Inicializa tabelas internas e variáveis
  PERFORM f_inicializa.

  PERFORM f_valida_processamento.

* Carrega o arquivo a ser processado
  PERFORM f_carrega_arquivo.

* Processa o arquivo carregado
  PERFORM f_processa_arquivo.

* Obtém a variante de planejamento
  PERFORM f_obtem_var_planejamento.

* Cria o usuário e a senha no E-recruiting
  PERFORM f_cria_usuario.

* Obtém candidaturas para a requisição
  PERFORM f_obtem_candidaturas.

* Grava dados pessoais
  PERFORM f_dados_pessoais.

*Grava Dados
  PERFORM f_grava_dados.

* Exibe relatório com log do processamento
  PERFORM f_exibe_relatorio.

*&---------------------------------------------------------------------*
*&      Form  f_inicializa
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM f_inicializa .

  REFRESH: t_data,
           t_dados,
           t_return,
           t_cand_cdcy,
           t_current_telef,
           t_current_addr,
           t_current_email,
           t_yeryt0001.

  CLEAR:   vg_data,
           wa_dados,
           wa_result,
           wa_req_hrobject,
           wa_salv_table,
           wa_columns.

ENDFORM.                    "f_inicializa
*&---------------------------------------------------------------------*
*&      Form  f_exibe_relatorio
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM f_exibe_relatorio .

  DATA: vl_repid TYPE syrepid,
        vl_texto TYPE char50,
        vl_lines TYPE numc06.

* Se não houver registros com erro, exibe log de sucesso
  IF t_return[] IS INITIAL.
    DESCRIBE TABLE t_data LINES vl_lines.
    CONCATENATE text-009 vl_lines text-010
           INTO vl_texto SEPARATED BY space.
    PERFORM f_grava_log USING vl_texto  vg_sucs  space  space.
  ENDIF.

  TRY.
      CALL METHOD cl_salv_table=>factory
        IMPORTING
          r_salv_table = wa_salv_table
        CHANGING
          t_table      = t_return.
    CATCH cx_salv_msg .

      LEAVE LIST-PROCESSING.
  ENDTRY.

  wa_columns = wa_salv_table->get_columns( ).
  wa_columns->set_optimize( c_x ).

* Monta a barra de ferramentas

  TRY.
      wa_salv_table->set_screen_status(
        pfstatus      = 'STANDARD_FULLSCREEN'"'STANDARD_ALV'
        report        = 'SAPLSLVC_FULLSCREEN'"vl_repid
        set_functions = wa_salv_table->c_functions_all ).
    CATCH cx_salv_object_not_found.                     "#EC NO_HANDLER
  ENDTRY.

* Exibe o relatório
  wa_salv_table->display( ).

ENDFORM.                    "f_exibe_relatorio
*&---------------------------------------------------------------------*
*&      Form  f_dados_pessoais
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM f_dados_pessoais .

  DATA: vl_usuario       TYPE bapialias,
        vl_bname         TYPE bapibname-bapibname,
        vl_cand_hrobject TYPE hrobject,
        wl_records       TYPE LINE OF rcf_t_p1000.


  LOOP AT t_data INTO wa_dados.
    wa_data = wa_dados.
    vl_usuario = wa_dados-cpf.

*   Obtém o usuário do candidato a partir do Alias
    PERFORM f_obtem_usuario CHANGING vl_usuario  vl_bname.

    CHECK NOT vl_bname IS INITIAL.

*   Obtém o ID do candidato (objeto NA)
    PERFORM f_obtem_id_cand CHANGING vl_bname    vl_cand_hrobject.

*   Obtém / Atualiza o infotipo 5202 (RG, CPF, Deficiência)
    PERFORM f_atualiza_5202 USING vl_cand_hrobject.

*   Obtém dados de comunicação
    PERFORM f_dados_comunicacao USING vl_cand_hrobject.

*   Atualiza o telefone residencial do candidado
    PERFORM f_atualiza_telef USING vl_cand_hrobject c_01 wa_dados-telcdt.

*   Atualiza o endereço do candidado
    PERFORM f_atualiza_endereco USING vl_cand_hrobject.

*   Obtém / Atualiza o infotipo 5200 (Número de inscrição)
    PERFORM f_atualiza_5200 USING vl_cand_hrobject.

*   Efetua a candidatura (associa o candidato à requisição: objeto NE)
    PERFORM f_efetua_candidatura CHANGING vl_cand_hrobject  wl_records.

  ENDLOOP.

ENDFORM.                    "f_dados_pessoais

*&---------------------------------------------------------------------*
*&      Form  f_efetua_candidatura
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_CAND_HROBJECT  text
*      -->P_RECORDS        text
*----------------------------------------------------------------------*
FORM f_efetua_candidatura  CHANGING  p_cand_hrobject TYPE hrobject
                                     p_records       TYPE LINE OF rcf_t_p1000.

  DATA:
    lo_cdcy          TYPE REF TO cl_hrrcf_candidacy_bl,
    wl_cand_cdcy     TYPE rcf_s_cand_cdcy,
    tl_cdcy_hrobject TYPE hrobject_tab,
    wl_cdcy_hrobject TYPE hrobject.

  CLEAR:lo_candidacy.

  CLEAR: wa_result, p_records.

  IF NOT lo_cdcy IS BOUND.
    lo_cdcy = cl_hrrcf_candidacy_bl=>get_instance( ).
  ENDIF.

  CHECK lo_cdcy IS BOUND.

* Primeiro verifica se o candidato possui candidaturas para a requisição
  READ TABLE t_cand_cdcy INTO wl_cand_cdcy
                      WITH KEY cand_hrobject = p_cand_hrobject.
  IF sy-subrc IS INITIAL.
    wa_result = wa_dados-cpf.
    PERFORM f_grava_log USING wa_result 'E' wa_dados-cpf text-016.

  ELSE.
* Se não possuir, efetua a candidatura (cria objeto NE)
    TRY.

        CLEAR lo_candidacy.
        CALL METHOD lo_cdcy->create_candidacy
          EXPORTING
            ps_cand_hrobject = p_cand_hrobject
            ps_req_hrobject  = wa_req_hrobject
          IMPORTING
            po_candidacy     = lo_candidacy.

*       Carrega a work area com ligação NE (infotipo 1000)
        READ TABLE lo_candidacy->records INTO p_records INDEX 1.

      CATCH cx_hrrcf INTO og_ex.
        wa_result = og_ex->get_text( ).
        PERFORM f_grava_log USING wa_result 'E' wa_dados-cpf text-012.

    ENDTRY.

  ENDIF.

ENDFORM.                    "f_efetua_candidatura
*&---------------------------------------------------------------------*
*&      Form  f_atualiza_5200
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_CAND_HROBJECT  text
*----------------------------------------------------------------------*
FORM f_atualiza_5200  USING  p_cand_hrobject TYPE hrobject.

  DATA: tl_5200      TYPE STANDARD TABLE OF p5200,
        tl_5102      TYPE STANDARD TABLE OF p5102,
        wl_5200      TYPE STANDARD TABLE OF p5200,
        wl_erro_5200 TYPE rcf_return_message.

  FIELD-SYMBOLS: <fs_5200> TYPE p5200,
                 <fs_5102> TYPE p5102.

  CONSTANTS: c_otype   TYPE plog-otype     VALUE 'NA',
             c_infty   TYPE infty          VALUE '5200',
             c_infty_2 TYPE infty          VALUE '5102',
             c_vtask   TYPE hrrhap-vtask   VALUE 'D',
             c_status  TYPE hrp5102-status VALUE '2'.

  CLEAR wa_result.

  CALL FUNCTION 'RH_READ_INFTY'
    EXPORTING
      with_stru_auth       = abap_true
      plvar                = vg_plvar
      otype                = c_otype
      objid                = p_cand_hrobject-objid
      infty                = c_infty
    TABLES
      innnn                = tl_5200
    EXCEPTIONS
      all_infty_with_subty = 1
      nothing_found        = 2
      no_objects           = 3
      wrong_condition      = 4
      wrong_parameters     = 5
      OTHERS               = 6.

  IF sy-subrc <> 0.

    APPEND INITIAL LINE TO tl_5200 ASSIGNING <fs_5200>.
    <fs_5200>-plvar                     = vg_plvar.
    <fs_5200>-otype                     = 'NA'.
    <fs_5200>-objid                     = p_cand_hrobject-objid.
    <fs_5200>-istat                     = 1.
    <fs_5200>-begda                     = sy-datum.
    <fs_5200>-endda                     = c_endda.
    <fs_5200>-infty                     = c_5200.
    <fs_5200>-objid                     = p_cand_hrobject-objid.
    <fs_5200>-zznumero_inscricao        = wa_dados-nminccdt.
    <fs_5200>-zznota_pocg               = wa_dados-notprobj.
    <fs_5200>-zznota_poce               = wa_dados-notprobje.
    <fs_5200>-zznota_fpo                = wa_dados-notfiprb.
    <fs_5200>-zzsituacao_cpo            = wa_dados-stcdtprb.
    <fs_5200>-zzsituacao_cpo            = wa_dados-clcdtprb.
    <fs_5200>-zzclassificacao_cpod      = wa_dados-clcdtprbde.
    <fs_5200>-zzclassificacao_fc_cn     = wa_dados-clcdtprbne.
    <fs_5200>-zznota_pd                 = wa_dados-ntprvdis.
    <fs_5200>-zzsituacao_cpd            = wa_dados-stcdtprdi.
    <fs_5200>-zzclassificacao_fc        = wa_dados-clafncdt.
    <fs_5200>-zzclassificacao_fc_d      = wa_dados-clafncdtd.
    <fs_5200>-zzclassificacao_fc_cn     = wa_dados-clafncdtn.
    <fs_5200>-zzindicacao_cc_sj         = wa_dados-incdtsubj.


    CALL FUNCTION 'RH_INSERT_INFTY'
      EXPORTING
        vtask               = c_vtask
      TABLES
        innnn               = tl_5200
      EXCEPTIONS
        no_authorization    = 1
        error_during_insert = 2
        repid_form_initial  = 3
        corr_exit           = 4
        begda_greater_endda = 5
        OTHERS              = 6.

    COMMIT WORK AND WAIT .
  ELSE.

    LOOP AT  tl_5200 ASSIGNING <fs_5200>.
      <fs_5200>-zznumero_inscricao        = wa_dados-nminccdt.
      <fs_5200>-zznota_pocg               = wa_dados-notprobj.
      <fs_5200>-zznota_poce               = wa_dados-notprobje.
      <fs_5200>-zznota_fpo                = wa_dados-notfiprb.
      <fs_5200>-zzsituacao_cpo            = wa_dados-stcdtprb.
      <fs_5200>-zzsituacao_cpo            = wa_dados-clcdtprb.
      <fs_5200>-zzclassificacao_cpod      = wa_dados-clcdtprbde.
      <fs_5200>-zzclassificacao_fc_cn     = wa_dados-clcdtprbne.
      <fs_5200>-zznota_pd                 = wa_dados-ntprvdis.
      <fs_5200>-zzsituacao_cpd            = wa_dados-stcdtprdi.
      <fs_5200>-zzclassificacao_fc        = wa_dados-clafncdt.
      <fs_5200>-zzclassificacao_fc_d      = wa_dados-clafncdtd.
      <fs_5200>-zzclassificacao_fc_cn     = wa_dados-clafncdtn.
      <fs_5200>-zzindicacao_cc_sj         = wa_dados-incdtsubj.
    ENDLOOP.

    IF NOT tl_5200 IS INITIAL.
      CALL FUNCTION 'RH_UPDATE_INFTY'
        EXPORTING
          vtask               = c_vtask "PD Update in Buffer = "D"
        TABLES
          innnn               = tl_5200
        EXCEPTIONS
          error_during_update = 1
          no_authorization    = 2
          repid_form_initial  = 3
          corr_exit           = 4
          OTHERS              = 5.

      COMMIT WORK AND WAIT .
    ENDIF.
  ENDIF.

*** Atualiza Status do Infotipo/Ligação Temporal 5201

  IF NOT tl_5200 IS INITIAL.
    CALL FUNCTION 'RH_READ_INFTY'
      EXPORTING
        with_stru_auth       = abap_true
        plvar                = vg_plvar
        otype                = c_otype
        objid                = p_cand_hrobject-objid
        infty                = c_infty_2
      TABLES
        innnn                = tl_5102
      EXCEPTIONS
        all_infty_with_subty = 1
        nothing_found        = 2
        no_objects           = 3
        wrong_condition      = 4
        wrong_parameters     = 5
        OTHERS               = 6.

    IF sy-subrc NE 0.
      MOVE-CORRESPONDING tl_5200[] TO tl_5102[].

      LOOP AT tl_5102 ASSIGNING <fs_5102>.
        <fs_5102>-status = c_status.
      ENDLOOP.

      CALL FUNCTION 'RH_INSERT_INFTY'
        EXPORTING
          vtask               = c_vtask
        TABLES
          innnn               = tl_5102
        EXCEPTIONS
          no_authorization    = 1
          error_during_insert = 2
          repid_form_initial  = 3
          corr_exit           = 4
          begda_greater_endda = 5
          OTHERS              = 6.

      COMMIT WORK AND WAIT .
    ELSE.

      LOOP AT tl_5102 ASSIGNING <fs_5102>.
        <fs_5102>-status = c_status.
      ENDLOOP.


      CALL FUNCTION 'RH_UPDATE_INFTY'
        EXPORTING
          vtask               = c_vtask "PD Update in Buffer = "D"
        TABLES
          innnn               = tl_5102
        EXCEPTIONS
          error_during_update = 1
          no_authorization    = 2
          repid_form_initial  = 3
          corr_exit           = 4
          OTHERS              = 5.

      COMMIT WORK AND WAIT .

    ENDIF.

  ENDIF.


ENDFORM.                    "f_atualiza_5200
*&---------------------------------------------------------------------*
*&      Form  f_atualiza_endereco
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_CAND_HROBJECT  text
*----------------------------------------------------------------------*
FORM f_atualiza_endereco  USING  p_cand_hrobject TYPE hrobject.

  DATA: wl_addressdata TYPE rcf_s_addressdata_bp,
        wl_address     TYPE rcf_s_addressdata_bp,
        vl_operation   TYPE rcf_opera,
        tl_return      TYPE bapirettab.

  CLEAR wa_result.

  wl_addressdata-street          = wa_dados-endcdt.
  wl_addressdata-postl_cod1      = wa_dados-cepcdt.
  wl_addressdata-city            = wa_dados-cidadcdt.
  wl_addressdata-region          = wa_dados-sigufcdt.
  wl_addressdata-country         = 'BR'.

  CHECK NOT wl_addressdata IS INITIAL.

  wl_addressdata-standardaddress = c_x.
  wl_addressdata-channel         = 01."03.

  TRY.
      SORT t_current_addr BY channel.
*    Verifica se é modificação ou inserção de registro
      READ TABLE t_current_addr
        WITH KEY channel = wl_addressdata-channel INTO wl_address BINARY SEARCH.

      IF sy-subrc EQ 0.
        IF wl_addressdata IS INITIAL.
          vl_operation = cl_hrrcf_abstract_controller=>delete_operation.
          CLEAR wl_addressdata.
          MOVE wl_address TO wl_addressdata.
        ELSEIF wl_addressdata EQ wl_address.
          vl_operation = space.
        ELSE.
          MOVE wl_address-addrnr TO wl_addressdata-addrnr.
          vl_operation = cl_hrrcf_abstract_controller=>modify_operation.
        ENDIF.
      ELSE.
        IF wl_addressdata IS INITIAL.
          vl_operation = space.
        ELSE.
          vl_operation = cl_hrrcf_abstract_controller=>insert_operation.
        ENDIF.
      ENDIF.

*     Atualiza o endereço do candidato
      IF vl_operation NE space.

        CALL METHOD og_bupa->maintain_address_data
          EXPORTING
            ps_cand_hrobject = p_cand_hrobject
            ps_addressdata   = wl_addressdata
            p_operation      = vl_operation
          IMPORTING
            pt_return        = tl_return.

        IF NOT tl_return[] IS INITIAL.
          APPEND LINES OF tl_return TO t_return.
        ENDIF.

      ENDIF.

    CATCH cx_hrrcf INTO og_ex.
      wa_result = og_ex->get_text( ).
      PERFORM f_grava_log USING wa_result 'E' wa_dados-cpf text-014.

  ENDTRY.

ENDFORM.                    "f_atualiza_endereco
*&---------------------------------------------------------------------*
*&      Form  f_atualiza_telef
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_CAND_HROBJECT  text
*      -->P_CHANNEL        text
*      -->P_TELEPHONE      text
*----------------------------------------------------------------------*
FORM f_atualiza_telef  USING  p_cand_hrobject TYPE hrobject
                              p_channel       TYPE any
                              p_telephone     TYPE any.

  DATA: wl_telefondata TYPE rcf_s_telefondata_bp,
        wl_telefon     TYPE rcf_s_telefondata_bp,
        vl_operation   TYPE rcf_opera,
        tl_return      TYPE bapirettab.

  CLEAR wa_result.

  wl_telefondata-channel   = p_channel.
  wl_telefondata-telephone = p_telephone.

  TRY.
      SORT t_current_telef BY channel.
      READ TABLE t_current_telef
        WITH KEY channel = wl_telefondata-channel INTO wl_telefon BINARY SEARCH.

*     Verifica se é modificação ou inserção de registro
      IF sy-subrc EQ 0.
        IF wl_telefondata-telephone IS INITIAL.
          vl_operation = cl_hrrcf_abstract_controller=>delete_operation.
          CLEAR wl_telefondata.
          MOVE wl_telefon TO wl_telefondata.
        ELSEIF ( wl_telefondata-telephone EQ wl_telefon-telephone ) AND
               ( wl_telefondata-std_no    EQ wl_telefon-std_no ).
          vl_operation = space.
        ELSE.
          MOVE wl_telefon-consnumber TO wl_telefondata-consnumber.
          vl_operation = cl_hrrcf_abstract_controller=>modify_operation.
        ENDIF.
      ELSE.
        IF wl_telefondata-telephone IS INITIAL.
          vl_operation = space.
        ELSE.
          vl_operation = cl_hrrcf_abstract_controller=>insert_operation.
        ENDIF.
      ENDIF.

*     Atualiza o telefone do candidato
      IF vl_operation NE space.

        CALL METHOD og_bupa->maintain_telefon_data
          EXPORTING
            ps_cand_hrobject = p_cand_hrobject
            ps_telefondata   = wl_telefondata
            p_operation      = vl_operation
          IMPORTING
            pt_return        = tl_return.

        IF NOT tl_return[] IS INITIAL.
          APPEND LINES OF tl_return TO t_return.
        ENDIF.

      ENDIF.

    CATCH cx_hrrcf INTO og_ex.
      wa_result = og_ex->get_text( ).
      PERFORM f_grava_log USING wa_result vg_erro wa_dados-cpf text-005.

  ENDTRY.

ENDFORM.                    "f_atualiza_telef
*&---------------------------------------------------------------------*
*&      Form  f_dados_comunicacao
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_CAND_HROBJECT  text
*----------------------------------------------------------------------*
FORM f_dados_comunicacao  USING  p_cand_hrobject TYPE hrobject.

  CLEAR wa_result.

  IF NOT og_bupa IS BOUND.
    og_bupa = cl_hrrcf_candidate_bupa_bl=>get_instance( ).
  ENDIF.

  CHECK og_bupa IS BOUND.

  REFRESH: t_current_telef, t_current_addr, t_current_email.

* Obtém dados atuais de telefone, endereço e e-mail
  TRY.
      CALL METHOD og_bupa->get_contact_data
        EXPORTING
          ps_cand_hrobject = p_cand_hrobject
        IMPORTING
          pt_telefondata   = t_current_telef
          pt_addressdata   = t_current_addr
          pt_emaildata     = t_current_email.

    CATCH cx_hrrcf INTO og_ex.
      wa_result = og_ex->get_text( ).
      PERFORM f_grava_log USING wa_result vg_erro wa_dados-cpf space.
  ENDTRY.

ENDFORM.                    "f_dados_comunicacao
*&---------------------------------------------------------------------*
*&      Form  f_atualiza_5202
*&---------------------------------------------------------------------*
*----------------------------------------------------------------------*
*      -->P_CAND_HROBJECT  text
*----------------------------------------------------------------------*
FORM f_atualiza_5202  USING  p_cand_hrobject TYPE hrobject.

  DATA: lo_5202      TYPE REF TO cl_hrpad_brpbs_iftyp5202,
        wl_5202      TYPE p5202,
        wl_erro_5202 TYPE rcf_return_message.

  CLEAR wa_result.

  IF NOT lo_5202 IS BOUND.
    CREATE OBJECT lo_5202.
  ENDIF.

  CHECK lo_5202 IS BOUND.

  TRY.
*     Obtém o infotipo 5202
      CALL METHOD lo_5202->get_record
        EXPORTING
          object_id = p_cand_hrobject-objid.

      wl_5202 = lo_5202->current_record.

      DATA(vl_fm) = wa_dados-tipfamili.

      TRANSLATE vl_fm TO UPPER CASE.

      IF vl_fm(1) = c_mae.
        vl_fm = '12'.
      ELSEIF vl_fm(1) = c_pai.
        vl_fm = '11'.
      ELSE.
        CLEAR vl_fm.
      ENDIF.

*     Atualiza registros do infotipo 5202
      IF NOT wl_5202 IS INITIAL.
        wl_5202-uname                = wa_dados-nomecdt.  "NOMECAND
        wl_5202-cpfnr                = wa_dados-cpf.      "CPF
        wl_5202-ident                = wa_dados-identcdt. "RG
        wl_5202-sbgru                = wa_dados-cdtptnec. "GRUP DEF
        wl_5202-race                 = wa_dados-cdtdnegr. "ETNIA
        wl_5202-zztipo_de_familiar01 = wa_dados-tipfamili."TIP.FAMILI
        wl_5202-zzfiliacao01         = vl_fm.             "FILIACAO
        lo_5202->current_record      = wl_5202.
        CALL METHOD lo_5202->modify.
      ELSE.
        wl_5202-objid                = p_cand_hrobject-objid.
        wl_5202-uname                = wa_dados-nomecdt.    "NOMECAND
        wl_5202-cpfnr                = wa_dados-cpf.        "CPF
        wl_5202-ident                = wa_dados-identcdt.   "RG
        wl_5202-sbgru                = wa_dados-cdtptnec.   "GRUP DEF
        wl_5202-race                 = wa_dados-cdtdnegr.   "ETNIA
        wl_5202-zztipo_de_familiar01 = wa_dados-tipfamili.  "TIP.FAMILI
        wl_5202-zzfiliacao01         = vl_fm.               "FILIACAO
        lo_5202->current_record      = wl_5202.
        CALL METHOD lo_5202->insert.
      ENDIF.

      wl_erro_5202 = lo_5202->return_message.


      IF NOT wl_erro_5202 IS INITIAL.
        wa_result = wl_erro_5202.
        PERFORM f_grava_log USING wa_result vg_erro wa_dados-cpf text-006.
      ENDIF.

    CATCH cx_hrrcf INTO og_ex.
      wa_result = og_ex->get_text( ).
      PERFORM f_grava_log USING wa_result vg_erro wa_dados-cpf text-006.
  ENDTRY.
ENDFORM.                    "f_atualiza_5202
*&---------------------------------------------------------------------*
*&      Form  f_obtem_id_cand
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_BNAME          text
*      -->P_CAND_HROBJECT  text
*----------------------------------------------------------------------*
FORM f_obtem_id_cand  CHANGING p_bname         TYPE bapibname-bapibname
                               p_cand_hrobject TYPE hrobject.

  CLEAR: og_candidate.
  CLEAR wa_result.

  TRY.
      CALL METHOD cl_hrrcf_candidate=>get
        EXPORTING
          user      = p_bname
        IMPORTING
          candidate = og_candidate.

      p_cand_hrobject = og_candidate->hrobject.

    CATCH cx_hrrcf INTO og_ex.
      wa_result = og_ex->get_text( ).
      PERFORM f_grava_log USING wa_result vg_erro wa_dados-cpf space.
  ENDTRY.

ENDFORM.                    "f_obtem_id_cand
*&---------------------------------------------------------------------*
*&      Form  f_obtem_usuario
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_USUARIO  text
*      -->P_BNAME    text
*----------------------------------------------------------------------*
FORM f_obtem_usuario CHANGING p_usuario   TYPE bapialias
                              p_bname     TYPE bapibname-bapibname.

  CLEAR p_bname.

  CALL FUNCTION 'SUSR_USER_BNAME_FROM_ALIAS'
    EXPORTING
      alias          = p_usuario
    IMPORTING
      bname          = p_bname
    EXCEPTIONS
      no_bname_found = 1
      OTHERS         = 2.

  IF sy-subrc <> 0.
    CLEAR p_bname.
  ENDIF.

ENDFORM.                    "f_obtem_usuario
*&---------------------------------------------------------------------*
*&      Form  f_obtem_candidaturas
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM f_obtem_candidaturas .

  DATA: lo_cdcy     TYPE REF TO cl_hrrcf_candidacy_bl.


  CHECK NOT t_data[] IS INITIAL.

  CLEAR wa_result.

  IF NOT lo_cdcy IS BOUND.
    lo_cdcy = cl_hrrcf_candidacy_bl=>get_instance( ).
  ENDIF.

  CHECK lo_cdcy IS BOUND.

* Objeto NB (Requisição)
  wa_req_hrobject-plvar = vg_plvar.
  wa_req_hrobject-otype = 'NB'.
  wa_req_hrobject-objid = p_header.     "Requisição

* Obtém candidaturas (objeto NE) ligadas aos candidatos (objeto NA)
  TRY.
      CALL METHOD lo_cdcy->get_cdcy_list_cand_by_requi
        EXPORTING
          ps_req_hrobject = wa_req_hrobject
        IMPORTING
          pt_candidate    = t_cand_cdcy.
    CATCH cx_hrrcf INTO og_ex.
      wa_result = og_ex->get_text( ).
      PERFORM f_grava_log USING wa_result 'E' space text-007.
  ENDTRY.

ENDFORM.                    "f_obtem_candidaturas
*&---------------------------------------------------------------------*
*&      Form  f_processa_arquivo
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM f_processa_arquivo .
  DATA: vl_index TYPE sy-index.

  IF NOT t_data[] IS INITIAL.

    LOOP  AT t_data INTO wa_data.
      wa_dados = wa_data.
      vl_index = sy-tabix.
*   Valida o CPF antes de gravar o registro
      PERFORM f_valida_cpf CHANGING wa_data-cpf  wa_result.
      IF NOT wa_result IS INITIAL.
        PERFORM f_grava_log USING wa_result vg_erro wa_data-cpf space.
        DELETE t_data INDEX vl_index.
      ENDIF.
    ENDLOOP.
  ENDIF.

ENDFORM.                    "f_processa_arquivo
*&---------------------------------------------------------------------*
*&      Form  f_cria_usuario
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM f_cria_usuario .

  DATA: wl_person  TYPE bapibus1006_central_person,
        vl_usuario TYPE bapialias,
        vl_bname   TYPE bapibname-bapibname,
        vl_senha   TYPE bapipwd        VALUE 'inicial',
        vl_email   TYPE bapiaddr3-e_mail,
        tl_return  TYPE bapirettab.

  LOOP AT t_data INTO wa_dados.

    REFRESH: tl_return.
    CLEAR:   vl_usuario, vl_email, wl_person, wa_result.

    wl_person-firstname          = wa_dados-nomecdt.
    SPLIT wa_dados-nomecdt AT space INTO  wl_person-firstname wl_person-lastname.

    wl_person-correspondlanguage = sy-langu.

    CONCATENATE wa_dados-dtnascdt+6(4) wa_dados-dtnascdt+3(2) wa_dados-dtnascdt(2) INTO wl_person-birthdate.
    vl_email            = wa_dados-endeletr.
    vl_usuario          = wa_dados-cpf.

*   Verifica se o candidato já existe na base usando o Alias (CPF)
    PERFORM f_obtem_usuario CHANGING vl_usuario  vl_bname.

    CHECK vl_bname IS INITIAL.

    TRY.
        CALL METHOD cl_hrrcf_candidate_admin_bl=>register
          EXPORTING
            ps_centraldataperson = wl_person
            p_email              = vl_email
            p_alias              = vl_usuario
            p_privacy_status     = c_x
            p_password           = vl_senha
            p_self_reg           = c_x
          IMPORTING
            pt_return            = tl_return.

        IF NOT tl_return[] IS INITIAL.
          APPEND LINES OF tl_return TO t_return.
        ENDIF.

      CATCH cx_hrrcf INTO og_ex.
        wa_result = og_ex->get_text( ).
        PERFORM f_grava_log USING wa_result 'E' vl_usuario space.
    ENDTRY.

  ENDLOOP.

ENDFORM.                    "f_cria_usuario

*&---------------------------------------------------------------------*
*&      Form  f_obtem_var_planejamento
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM f_obtem_var_planejamento.

  CALL FUNCTION 'RH_GET_ACTIVE_WF_PLVAR'
    IMPORTING
      act_plvar       = vg_plvar
    EXCEPTIONS
      no_active_plvar = 1
      OTHERS          = 2.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

ENDFORM.                    "f_obtem_var_planejamento
*&---------------------------------------------------------------------*
*&      Form  f_carrega_arquivo
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM f_carrega_arquivo.
*  IF p_locl EQ 'X'.
  PERFORM z_upload_file.
*  ELSEIF p_serv EQ 'X'.
*    PERFORM z_upload_file_serv.
*  ENDIF.
ENDFORM.                    "f_carrega_arquivo

*&---------------------------------------------------------------------*
*&      Form  z_upload_file
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM z_upload_file.

  CALL FUNCTION 'TEXT_CONVERT_XLS_TO_SAP'
    EXPORTING
      i_field_seperator    = 'X'
      i_line_header        = 'X'
      i_tab_raw_data       = t_raw       " WORK TABLE
      i_filename           = p_file
    TABLES
      i_tab_converted_data = t_data[]    "ACTUAL DATA
    EXCEPTIONS
      conversion_failed    = 1
      OTHERS               = 2.

  IF sy-subrc <> 0.
    MESSAGE e000(yhcm) WITH text-003.
    LEAVE LIST-PROCESSING.
  ENDIF.
ENDFORM.                    "z_upload_file
*&---------------------------------------------------------------------*
*&      Form  z_header_f4help
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM z_header_f4help.

* Obtem dados do match code
  PERFORM z_check_header.

* Chamada da Função F4
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'OBJID'
      dynpprog        = sy-repid    " Program name
      dynpnr          = sy-dynnr    " Screen number
      dynprofield     = 'P_HEADER'  " F4 help need field
      value_org       = 'S'
    TABLES
      value_tab       = t_f4header " F4 help values
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

ENDFORM.                    "z_header_f4help
*&---------------------------------------------------------------------*
*&      Form  z_buscafile
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->C_FILE     text
*----------------------------------------------------------------------*
FORM z_buscafile CHANGING c_file LIKE rlgrap-filename.

*---> strutura para armazenar caminho file
  DATA: BEGIN OF t_path OCCURS 0.
          INCLUDE STRUCTURE sdokpath.
  DATA: END OF t_path.

*---> função chama o file e armazena o caminho
  CALL FUNCTION 'TMP_GUI_FILE_OPEN_DIALOG'
    EXPORTING
      window_title   = 'Selecionar Arquivo'
      init_directory = 'C:\'
    TABLES
      file_table     = t_path
    EXCEPTIONS
      cntl_error     = 1
      OTHERS         = 2.

*---> se erro dispara mensagem, senão, armazena caminho em variável
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    READ TABLE t_path INDEX 1.
    c_file = t_path-pathname.
  ENDIF.

ENDFORM.                    " z_buscafile
*&---------------------------------------------------------------------*
*&      Form  z_check_requisicao
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM z_check_requisicao.

  IF p_header IS INITIAL.
    MESSAGE 'Informar Requisição' TYPE 'E'.
  ELSE.
    PERFORM z_check_header.
    SORT t_f4header BY objid.
    READ TABLE t_f4header TRANSPORTING NO FIELDS WITH KEY objid = p_header BINARY SEARCH.

    IF sy-subrc NE 0.
      MESSAGE 'Informar Requisição com Status 1' TYPE 'E'.
    ENDIF.
  ENDIF.
ENDFORM.                    "z_check_requisicao
*&---------------------------------------------------------------------*
*&      Form  z_check_header
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM z_check_header.

  REFRESH t_f4header.

  SELECT  objid
          header
       FROM hrp5125
       INTO TABLE t_f4header
  WHERE otype  EQ 'NB' AND
        status EQ 1.

ENDFORM.                    "z_check_header
*&---------------------------------------------------------------------*
*&      Form  f_grava_log
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_MSG      text
*      -->P_TYPE     text
*      -->P_USUARIO  text
*      -->P_INFTY    text
*----------------------------------------------------------------------*
FORM f_grava_log  USING  p_msg     TYPE any
                         p_type    TYPE any
                         p_usuario TYPE any
                         p_infty   TYPE any.

  DATA: wl_return TYPE  bapiret2,

        vl_msgv1  TYPE  symsgv,
        vl_msgv2  TYPE  symsgv,
        vl_msgv3  TYPE  symsgv.

  IF NOT p_msg IS INITIAL.
    vl_msgv1 = p_msg.
  ENDIF.

  IF NOT p_usuario IS INITIAL.
    CONCATENATE text-008 p_usuario INTO vl_msgv2 SEPARATED BY space.
    vl_msgv3 = text-t07.
  ENDIF.

  wl_return-type       = p_type.
  wl_return-id         = c_sy.
  wl_return-number     = c_002.
  wl_return-message    = p_type.
  wl_return-message_v1 = vl_msgv1.
  wl_return-message_v2 = vl_msgv2.
  wl_return-message_v3 = vl_msgv3.
  wl_return-message_v4 = p_infty.

  APPEND wl_return TO t_return.
  CLEAR  p_msg.

  IF wl_return-type = 'E'.
    CLEAR  wa_yeryt0001.
    wa_yeryt0001-cpf            = wa_dados-cpf.
    wa_yeryt0001-data           = sy-datum.
    wa_yeryt0001-hora           = sy-uzeit.
    wa_yeryt0001-email          = wa_dados-endeletr.
    wa_yeryt0001-nome           = wa_dados-nomecdt.
    wa_yeryt0001-classificacao  = wa_dados-clafncdt.
    wa_yeryt0001-tperro         = vg_erro.
    wa_yeryt0001-mensagem_erro  = vl_msgv1.

    INSERT wa_yeryt0001 INTO TABLE t_yeryt0001.
  ENDIF.

ENDFORM.                    "f_grava_log

*&---------------------------------------------------------------------*
*&      Form  f_valida_processamento
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM f_valida_processamento.

* Valida processamento background
  IF NOT sy-binpt IS INITIAL OR
     NOT sy-batch IS INITIAL.
*     Msg: Processamento background não permitido para arquivo local
    MESSAGE e000(yhcm) WITH text-002.
    LEAVE LIST-PROCESSING.
  ENDIF.
ENDFORM.                    "f_valida_processamento

*&---------------------------------------------------------------------*
*&      Form  f_valida_cpf
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_CPF      text
*      -->P_RETURN   text
*----------------------------------------------------------------------*
FORM f_valida_cpf  CHANGING p_cpf     TYPE any
                            p_return  TYPE any.

  CALL FUNCTION 'CONVERSION_EXIT_CPFBR_INPUT'
    EXPORTING
      input     = p_cpf
    IMPORTING
      output    = p_cpf
    EXCEPTIONS
      not_valid = 1
      OTHERS    = 2.
  IF sy-subrc <> 0.
    p_return = text-004.
  ENDIF.

ENDFORM.                    " F_VALIDA_CPF
*&---------------------------------------------------------------------*
*&      Form  F_GRAVA_DADOS
*&---------------------------------------------------------------------*
FORM f_grava_dados .

  IF t_yeryt0001[] IS NOT INITIAL.

    MODIFY yeryt0001 FROM TABLE t_yeryt0001[].
    COMMIT WORK AND WAIT .
  ENDIF.

ENDFORM.                    " F_GRAVA_DADOS
Contact GitHub 