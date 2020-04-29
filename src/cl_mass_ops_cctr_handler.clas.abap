CLASS cl_mass_ops_cctr_handler DEFINITION PUBLIC FINAL CREATE PRIVATE
GLOBAL FRIENDS cl_mass_ops_factory.

  PUBLIC SECTION.
    INTERFACES:
      if_mass_ops_cctr_handler.

    ALIASES:
      set_contract     FOR if_mass_ops_cctr_handler~set_contract,
      get_contract     FOR if_mass_ops_cctr_handler~get_contract,
      get_contracts    FOR if_mass_ops_cctr_handler~get_contracts,
      remove_contracts FOR if_mass_ops_cctr_handler~remove_contracts,
      update_documents FOR if_mass_ops_cctr_handler~update_documents,
      generate_logs    FOR if_mass_ops_cctr_handler~generate_logs.

    DATA: mv_no_commit TYPE boolean VALUE abap_false.

  PRIVATE SECTION.
    DATA:
      mt_central_purchasing_contract TYPE if_mass_ops_cctr_setter_getter~tt_central_purchasing_contract,
      mv_message_log_handler         TYPE balloghndl,
      mo_mm_cctr_handler             TYPE REF TO cl_central_ctr_handler_mm.

    CLASS-METHODS:
      create RETURNING VALUE(ro_instance) TYPE REF TO cl_mass_ops_cctr_handler.

    METHODS:
      _set_header_distribution      IMPORTING it_header_distributions TYPE if_mass_ops_cctr_setter_getter~tt_header_distribution
                                    CHANGING  ct_header_distributions TYPE if_mass_ops_cctr_setter_getter~tt_header_distribution,
      _set_item                     IMPORTING it_items TYPE if_mass_ops_cctr_setter_getter~tt_item
                                    CHANGING  ct_items TYPE if_mass_ops_cctr_setter_getter~tt_item,
      _set_item_distribution        IMPORTING it_item_distributions TYPE if_mass_ops_cctr_setter_getter~tt_item_distribution
                                    CHANGING  ct_item_distributions TYPE if_mass_ops_cctr_setter_getter~tt_item_distribution,
      _set_cctr_header              IMPORTING is_new_header TYPE outline_agrmnt_header_data
                                    CHANGING  cs_old_header TYPE outline_agrmnt_header_data,
      _set_cctr_header_distribution IMPORTING it_header_distributions TYPE if_mass_ops_cctr_setter_getter~tt_header_distribution,
      _set_cctr_items               IMPORTING it_items                TYPE if_mass_ops_cctr_setter_getter~tt_item,
      _set_cctr_item_distribution   IMPORTING iv_item_number        TYPE ebelp
                                              it_item_distributions TYPE if_mass_ops_cctr_setter_getter~tt_item_distribution,
      _move_data_by_structure       IMPORTING is_source      TYPE any
                                              is_source_flag TYPE any
                                    CHANGING  cs_target      TYPE any
                                              cs_target_flag TYPE any,
      _create_and_attach_msg_log    IMPORTING iv_business_object TYPE bal_s_log-subobject
                                    RETURNING VALUE(rv_success)  TYPE boolean,
      _add_msg_to_msg_log           IMPORTING it_messages       TYPE bal_t_msg
                                    RETURNING VALUE(rv_success) TYPE boolean,
      _persist_generated_log        RETURNING VALUE(rv_success) TYPE boolean,
      _insert_data                  IMPORTING is_structure TYPE any
                                    CHANGING  ct_table     TYPE ANY TABLE,
      _insert_table_data            IMPORTING it_table TYPE ANY TABLE
                                    CHANGING  ct_table TYPE ANY TABLE,
      _modify_data                  IMPORTING is_structure TYPE any
                                    CHANGING  ct_table     TYPE ANY TABLE.
ENDCLASS.



CLASS CL_MASS_OPS_CCTR_HANDLER IMPLEMENTATION.


  METHOD create.
    ro_instance = NEW cl_mass_ops_cctr_handler( ).
  ENDMETHOD.


  METHOD if_mass_ops_cctr_setter_getter~get_contract.
    rv_document = VALUE #( mt_central_purchasing_contract[ document_number = iv_document_number ] OPTIONAL ).
  ENDMETHOD.


  METHOD if_mass_ops_cctr_setter_getter~get_contracts.
    rt_documents = mt_central_purchasing_contract.
  ENDMETHOD.


  METHOD if_mass_ops_cctr_setter_getter~remove_contracts.
    IF lines( it_contracts ) > 0.
      DELETE mt_central_purchasing_contract WHERE document_number IN it_contracts.
    ENDIF.
  ENDMETHOD.


  METHOD if_mass_ops_cctr_setter_getter~set_contract.
*    Check if the current contract exists
    DATA(ls_central_purchasing_contract) = VALUE #( mt_central_purchasing_contract[ document_number = is_central_purchasing_contract-document_number ] OPTIONAL ).
*    If contract do not exist, then it is a new contract
    IF ls_central_purchasing_contract IS INITIAL.
      me->_insert_data( EXPORTING is_structure = is_central_purchasing_contract
                        CHANGING  ct_table     = mt_central_purchasing_contract ).
    ELSE.
*      Check if header is present, then populate header
      IF is_central_purchasing_contract-data IS NOT INITIAL.
        ls_central_purchasing_contract-data = is_central_purchasing_contract-data.
        ls_central_purchasing_contract-flag = is_central_purchasing_contract-flag.
      ENDIF.

*      Check if header distribution is present, then populate header distribution
      IF lines( is_central_purchasing_contract-header_distributions ) > 0.
        me->_set_header_distribution( EXPORTING it_header_distributions = is_central_purchasing_contract-header_distributions
                                      CHANGING  ct_header_distributions = ls_central_purchasing_contract-header_distributions ).
      ENDIF.

*      Check if item is present, then populate items
      IF lines( is_central_purchasing_contract-items ) > 0.
        me->_set_item( EXPORTING it_items = is_central_purchasing_contract-items
                       CHANGING  ct_items = ls_central_purchasing_contract-items ).
      ENDIF.
      me->_modify_data( EXPORTING is_structure = ls_central_purchasing_contract
                        CHANGING  ct_table     = mt_central_purchasing_contract ).
    ENDIF.
  ENDMETHOD.


  METHOD if_mass_ops_document_handler~generate_log.
    DATA(lv_status) = COND boolean( WHEN me->_create_and_attach_msg_log( iv_business_object = 'BUS2014' ) = abap_true
                                      THEN COND #( WHEN me->_add_msg_to_msg_log( it_messages ) = abap_true
                                                    THEN me->_persist_generated_log( ) ) ).
  ENDMETHOD.


  METHOD if_mass_ops_document_handler~update_document.
    CONSTANTS:
      lc_msg_class TYPE bal_s_msg-msgid VALUE 'APPL_MM_PUR_OA_CON',
      lc_msg_no    TYPE bal_s_msg-msgno VALUE 048.  " Document Currency cannot be updated
    "   Instantiate the Central Purchase Contract Handler
    mo_mm_cctr_handler = cl_central_ctr_handler_mm=>get_ctr_instance( ).

    LOOP AT mt_central_purchasing_contract ASSIGNING FIELD-SYMBOL(<fs_cntrl_purchasing_contract>).
      TRY.
          "   Open the current contract
          mo_mm_cctr_handler->open( im_ebeln        = <fs_cntrl_purchasing_contract>-document_number
                                    im_aktyp        = cl_mmpur_constants=>ver
                                    im_bstyp        = if_mass_ops_cctr_setter_getter~c_document_category ).

          "     Get the stored header detail for the current contract
          mo_mm_cctr_handler->get_outl_agrmnt_header( EXPORTING is_outl_agrmnt_read_flags = VALUE #( header = abap_true )
                                                      IMPORTING es_outl_agrmnt_header     = DATA(ls_header) ).

          """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""
          "         HEADER DATA
          """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""
          "     Check if header data exist, then populate the data
          IF <fs_cntrl_purchasing_contract>-data IS NOT INITIAL.
            "     Update header of the given contract
            me->_set_cctr_header( EXPORTING is_new_header = VALUE #( data  = <fs_cntrl_purchasing_contract>-data
                                                                   datax = <fs_cntrl_purchasing_contract>-flag )
                                CHANGING  cs_old_header = ls_header ).
          ENDIF.

          """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""
          "             HEADER DISTRIBUTION
          """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""
          "     Check if distribution at header level is present, then populate the current contract
          IF lines( <fs_cntrl_purchasing_contract>-header_distributions ) > 0.
            "       Update distribution lines of the header of a given contract
            me->_set_cctr_header_distribution( it_header_distributions = <fs_cntrl_purchasing_contract>-header_distributions ).
          ENDIF.

          "         There are certain item components in the object which are needs to filled before the processing of the items
          "         Hence, we need to process the already set header data.
          mo_mm_cctr_handler->outl_agrmnt_process( ).

          """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""
          "             ITEM
          """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""
          "     Check if item lines present, then populate the current contract
          IF lines( <fs_cntrl_purchasing_contract>-items ) > 0.
            "       Update the item lines for the given contract
            me->_set_cctr_items( it_items = <fs_cntrl_purchasing_contract>-items ).
          ENDIF.

          "     Process contract for errors
          mo_mm_cctr_handler->outl_agrmnt_process( IMPORTING ex_messages = DATA(lt_messages) ).

          "     Post the contract only if no errors are present or else if the contract is in "In Preparation" status and there is no document currency update.
          IF NOT line_exists( lt_messages[ msgty = 'E' ] ) OR
             ( ls_header-data-procstat EQ '01' AND ls_header-data-bsart IS NOT INITIAL AND NOT line_exists( lt_messages[ msgid = lc_msg_class msgno = lc_msg_no ] ) ).
            mo_mm_cctr_handler->outl_agrmnt_post( EXPORTING im_no_commit = mv_no_commit
                                                  IMPORTING ex_messages  = lt_messages ).
          ENDIF.

          "   Error Handling
          IF NOT line_exists( lt_messages[ msgty = 'E' ] ).
            "   Set success message.
            APPEND VALUE bal_s_msg( msgty = sy-abcde+18(1)
                                    msgid = 'MM'
                                    msgno = '899'
                                    msgv1 = replace( val = TEXT-001 sub = `&` with = ls_header-data-ebeln ) ) TO rt_messages.
          ELSE.
            "   Set information message about the contract
            APPEND VALUE bal_s_msg( msgty = sy-abcde+8(1)
                                    msgid = 'MM'
                                    msgno = '899'
                                    msgv1 = TEXT-002
                                    msgv2 = ls_header-data-ebeln ) TO rt_messages.
            "   Append all error message to the return table
            APPEND LINES OF CORRESPONDING bal_t_msg( lt_messages ) TO rt_messages.
          ENDIF.
        CATCH cx_mmpur_root.
          "handle exception
          cl_message_handler_mm=>get_handler( IMPORTING ex_handler = DATA(lo_message_handler) ).
          APPEND LINES OF CORRESPONDING bal_t_msg( lo_message_handler->get_list_for_bapi( ) ) TO rt_messages.
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.


  METHOD _add_msg_to_msg_log.
    "       Inject message into the log
    LOOP AT it_messages ASSIGNING FIELD-SYMBOL(<fs_message>).
      CALL FUNCTION 'BAL_LOG_MSG_ADD'
        EXPORTING
          i_log_handle     = mv_message_log_handler
          i_s_msg          = <fs_message>
        EXCEPTIONS
          log_not_found    = 1
          msg_inconsistent = 2
          log_is_full      = 3
          OTHERS           = 4.
      IF sy-subrc EQ 0.
        rv_success = abap_true.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD _create_and_attach_msg_log.
    "       Instantiate the log handler
    CALL FUNCTION 'BAL_LOG_CREATE'
      EXPORTING
        i_s_log                 = VALUE bal_s_log( object = 'MASS' subobject = iv_business_object aldate_del = sy-datum + 15 )
      IMPORTING
        e_log_handle            = mv_message_log_handler
      EXCEPTIONS
        log_header_inconsistent = 1
        OTHERS                  = 2.
    IF sy-subrc = 0.
      "   Register the log handler against the current running application
      CALL FUNCTION 'BP_ADD_APPL_LOG_HANDLE'
        EXPORTING
          loghandle                  = mv_message_log_handler
        EXCEPTIONS
          could_not_set_handle       = 1
          not_running_in_batch       = 2
          could_not_get_runtime_info = 3
          handle_already_exists      = 4
          locking_error              = 5
          OTHERS                     = 6.
      IF sy-subrc = 0.
        rv_success = abap_true.
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD _insert_data.
    TRY.
        INSERT is_structure INTO TABLE ct_table.
      CATCH cx_sy_itab_duplicate_key.
    ENDTRY.
  ENDMETHOD.


  METHOD _insert_table_data.
    TRY.
        INSERT LINES OF it_table INTO TABLE ct_table.
      CATCH cx_sy_itab_duplicate_key.
    ENDTRY.
  ENDMETHOD.


  METHOD _modify_data.
    TRY.
        MODIFY TABLE ct_table FROM is_structure.
      CATCH cx_sy_itab_dyn_loop.
    ENDTRY.
  ENDMETHOD.


  METHOD _move_data_by_structure.
    LOOP AT CAST cl_abap_structdescr( cl_abap_typedescr=>describe_by_data( p_data = is_source  ) )->components ASSIGNING FIELD-SYMBOL(<fs_component>).
      ASSIGN COMPONENT <fs_component>-name OF STRUCTURE: is_source      TO FIELD-SYMBOL(<fs_source_value>),
                                                         is_source_flag TO FIELD-SYMBOL(<fs_source_flag_value>),
                                                         cs_target      TO FIELD-SYMBOL(<fs_target_value>),
                                                         cs_target_flag TO FIELD-SYMBOL(<fs_target_flag_value>).

      IF <fs_component>-name = 'PROCMTHUBPREDECESSORDOCITEM' OR <fs_component>-name = 'PROCMTHUBPURREQUISITIONITEM'.
        CONTINUE.
      ENDIF.

      IF <fs_source_value> IS NOT ASSIGNED OR <fs_target_value> IS NOT ASSIGNED.
        CONTINUE.
      ENDIF.

      IF <fs_source_flag_value> = abap_true AND <fs_target_value> NE <fs_source_value>.
        <fs_target_value>      = <fs_source_value>.
        <fs_target_flag_value> = abap_true.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.


  METHOD _persist_generated_log.
    "       Persist the messages to the log generated
    CALL FUNCTION 'BAL_DB_SAVE'
      EXPORTING
        i_client         = sy-mandt
        i_t_log_handle   = VALUE bal_t_logh( ( mv_message_log_handler ) )
      EXCEPTIONS
        log_not_found    = 1
        save_not_allowed = 2
        numbering_error  = 3
        OTHERS           = 4.
    IF sy-subrc = 0.
      rv_success = abap_true.
    ENDIF.
  ENDMETHOD.


  METHOD _set_cctr_header.
    me->_move_data_by_structure( EXPORTING is_source      = is_new_header-data
                                           is_source_flag = is_new_header-datax
                                 CHANGING  cs_target      = cs_old_header-data
                                           cs_target_flag = cs_old_header-datax ).
    "   Set the updated header data to the current contract
    mo_mm_cctr_handler->set_outl_agreement_header( is_outl_agrmnt_header    = cs_old_header
                                                   is_outl_agrmnt_set_flags = VALUE #( header = abap_true ) ).
  ENDMETHOD.


  METHOD _set_cctr_header_distribution.
    "   Get details of the existing distribution details for header from the DB
    mo_mm_cctr_handler->get_outl_agrmnt_hdr_dist( IMPORTING et_distributions = DATA(lt_distributions) ).

    "   Process each distribution line.
    LOOP AT it_header_distributions ASSIGNING FIELD-SYMBOL(<fs_distribution>).
      "  Check if current distribution line exists in DB, then update, else insert
      READ TABLE lt_distributions ASSIGNING FIELD-SYMBOL(<fs_distr>) WITH KEY data-purchasingdocument = <fs_distribution>-data-purchasingdocument
                                                                              data-distributionnumber = <fs_distribution>-data-distributionnumber.
      IF sy-subrc = 0.
        me->_move_data_by_structure( EXPORTING is_source      = <fs_distribution>-data
                                               is_source_flag = <fs_distribution>-flag
                                     CHANGING  cs_target      = <fs_distr>-data
                                               cs_target_flag = <fs_distr>-datax ).
*      ELSE.
*        APPEND VALUE #( data  = <fs_distribution>-data
*                        datax = <fs_distribution>-flag ) TO lt_distributions.
      ENDIF.
    ENDLOOP.
    "   Set the updated distribution lines at the header to the current contract
    mo_mm_cctr_handler->set_outl_agrmnt_hdr_dist( it_distribution_lines = lt_distributions ).

    CLEAR lt_distributions.
  ENDMETHOD.


  METHOD _set_cctr_items.
    "   Get details of the existing item lines for the given contract
    mo_mm_cctr_handler->get_outl_agrmnt_items( EXPORTING is_item_read_flag = VALUE #( item = abap_true )
                                               IMPORTING et_item           = DATA(lt_items) ).

    "    Process each item line
    LOOP AT it_items ASSIGNING FIELD-SYMBOL(<fs_item>).
      "   Check if current item line exists in DB, then update else insert
      READ TABLE lt_items ASSIGNING FIELD-SYMBOL(<fs_itm>) WITH KEY data-ebeln = <fs_item>-data-ebeln
                                                                    data-ebelp = <fs_item>-data-ebelp.
      IF sy-subrc = 0.
        me->_move_data_by_structure( EXPORTING is_source      = <fs_item>-data
                                               is_source_flag = <fs_item>-flag
                                     CHANGING  cs_target      = <fs_itm>-data
                                               cs_target_flag = <fs_itm>-datax ).
*      ELSE.
*        APPEND VALUE #( data  = <fs_item>-data
*                        datax = <fs_item>-flag ) TO lt_items.
      ENDIF.

      """"""""""""""""""""""""""""""""""""""""""""""""""""""""
      "             ITEM DISTRIBUTIONS
      """"""""""""""""""""""""""""""""""""""""""""""""""""""""
      IF lines( <fs_item>-item_distribution ) > 0.
        "       Update the item distributions for the current item
        me->_set_cctr_item_distribution( iv_item_number        = <fs_item>-data-ebelp
                                       it_item_distributions = <fs_item>-item_distribution ).
      ENDIF.
      """"""""""""""""""""""""""""""""""""""""""""""""""""""""
    ENDLOOP.
    "   Set the updated item line to the current contract
    mo_mm_cctr_handler->set_outl_agrrement_items( it_items          = VALUE outline_agrmnt_t_item( FOR <fs_contract_itm> IN lt_items ( data  = <fs_contract_itm>-data
                                                                                                                                       datax = <fs_contract_itm>-datax ) )
                                                  is_item_set_flags = VALUE #( item = abap_true ) ).
  ENDMETHOD.


  METHOD _set_cctr_item_distribution.
    "   Get details of the existing distribution lines at current item level for the given contract
    mo_mm_cctr_handler->get_out_agrmnt_itm_dist( EXPORTING iv_item_no       = iv_item_number
                                                 IMPORTING et_distributions = DATA(lt_distributions) ).

    " Process each distribution line
    LOOP AT it_item_distributions ASSIGNING FIELD-SYMBOL(<fs_distribution>).
      "   Check if current distribution line exists, then update else insert
      READ TABLE lt_distributions ASSIGNING FIELD-SYMBOL(<fs_distr>) WITH KEY data-purchasingdocument     = <fs_distribution>-data-purchasingdocument
                                                                              data-purchasingdocumentitem = <fs_distribution>-data-purchasingdocumentitem
                                                                              data-distributionnumber     = <fs_distribution>-data-distributionnumber.
      IF sy-subrc = 0.
        me->_move_data_by_structure( EXPORTING is_source      = <fs_distribution>-data
                                               is_source_flag = <fs_distribution>-flag
                                     CHANGING  cs_target      = <fs_distr>-data
                                               cs_target_flag = <fs_distr>-datax ).
*      ELSE.
*        APPEND VALUE #( data  = <fs_distribution>-data
*                        datax = <fs_distribution>-flag ) TO lt_distributions.
      ENDIF.
    ENDLOOP.
    "   Set the updated distribution lines at the item level to the current contract
    mo_mm_cctr_handler->set_outl_agrmnt_itm_dist( iv_item_no            = iv_item_number
                                                  iv_item_id            = ''
                                                  it_distribution_lines = lt_distributions ).

    CLEAR lt_distributions.

  ENDMETHOD.


  METHOD _set_header_distribution.
    IF lines( ct_header_distributions ) = 0.
*            No existing data present hence insert current data
      me->_insert_table_data( EXPORTING it_table = it_header_distributions
                              CHANGING  ct_table = ct_header_distributions ).
    ELSE.
*            Existing data is present hence check and modify
      LOOP AT it_header_distributions ASSIGNING FIELD-SYMBOL(<fs_header_distribution>).
*            Check if current record exist
        IF line_exists( ct_header_distributions[ data-purchasingdocument = <fs_header_distribution>-data-purchasingdocument
                                                 data-distributionnumber = <fs_header_distribution>-data-distributionnumber ] ).
*            Modify the existing record with the new values
          me->_modify_data( EXPORTING is_structure = <fs_header_distribution>
                            CHANGING  ct_table     = ct_header_distributions ).
        ELSE.
*            Record do not exist, hence insert the new record
          me->_insert_data( EXPORTING is_structure = <fs_header_distribution>
                            CHANGING  ct_table     = ct_header_distributions ).
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.


  METHOD _set_item.
    IF lines( ct_items ) = 0.
*        No existing data present hence insert current data [Item & Item Distributions]
      me->_insert_table_data( EXPORTING it_table = it_items
                              CHANGING  ct_table = ct_items ).
    ELSE.
*        Existing data is present hence check and modify
      LOOP AT it_items ASSIGNING FIELD-SYMBOL(<fs_item>).
*        Check if current record exist
        DATA(ls_item) = VALUE #( ct_items[ data-ebeln = <fs_item>-data-ebeln
                                           data-ebelp = <fs_item>-data-ebelp ] OPTIONAL ).
        IF ls_item IS NOT INITIAL.
          IF <fs_item>-flag  IS NOT INITIAL.
            ls_item-data = <fs_item>-data.
            ls_item-flag = <fs_item>-flag.
          ENDIF.

*            Check if Item Distributions is present, then populate item distribution
          IF lines( <fs_item>-item_distribution ) > 0.
            me->_set_item_distribution( EXPORTING it_item_distributions = <fs_item>-item_distribution
                                        CHANGING  ct_item_distributions = ls_item-item_distribution ).
          ENDIF.
*            Modify the existing record with the new values
          me->_modify_data( EXPORTING is_structure = ls_item
                            CHANGING  ct_table     = ct_items ).
        ELSE.
*            Record do not exist, hence insert the new record
          me->_insert_data( EXPORTING is_structure = <fs_item>
                            CHANGING  ct_table     = ct_items ).
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.


  METHOD _set_item_distribution.
*    Existing data is present, hence check and modify
    LOOP AT it_item_distributions ASSIGNING FIELD-SYMBOL(<fs_item_distribution>).
*        Check if current record exists
      IF line_exists( ct_item_distributions[ data-purchasingdocument     = <fs_item_distribution>-data-purchasingdocument
                                             data-purchasingdocumentitem = <fs_item_distribution>-data-purchasingdocumentitem
                                             data-distributionnumber     = <fs_item_distribution>-data-distributionnumber ] ).
*            Modify the existing record
        me->_modify_data( EXPORTING is_structure = <fs_item_distribution>
                          CHANGING  ct_table     = ct_item_distributions ).
      ELSE.
*            Record do not exist, hence insert the new record
        me->_insert_data( EXPORTING is_structure = <fs_item_distribution>
                          CHANGING  ct_table     = ct_item_distributions ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
