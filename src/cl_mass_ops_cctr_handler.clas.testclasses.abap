*"* use this source file for your ABAP unit test classes

CLASS ltc_mass_ops_cctr_handler DEFINITION FINAL FOR TESTING DURATION LONG RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    DATA:
            mo_cut TYPE REF TO cl_mass_ops_cctr_handler.

    METHODS: setup,
      set_contract FOR TESTING.

ENDCLASS.

CLASS ltc_mass_ops_cctr_handler IMPLEMENTATION.

  METHOD setup.

    mo_cut = cast #( cl_mass_ops_factory=>get_mass_ops_cctr_instance( ) ).

  ENDMETHOD.

  METHOD set_contract.
    mo_cut->set_contract( is_central_purchasing_contract = VALUE if_mass_ops_cctr_setter_getter=>ty_central_purchasing_document( ) ).

    " Header
    mo_cut->set_contract( is_central_purchasing_contract = VALUE #( document_number = '123'
                                                                                                   data   = VALUE #( ebeln = '123' )  ) ).

    mo_cut->set_contract( is_central_purchasing_contract = VALUE #( document_number = '123'
                                                                                                   data   = VALUE #( ebeln = '123' bsart = 'C' )  ) ).
    "   Header Distribution
    mo_cut->set_contract( is_central_purchasing_contract = VALUE #( document_number = '123'
                                                                                                   header_distributions  = VALUE #( ( data-purchasingdocument = '123' data-distributionnumber = '1' ) ) ) ).

    mo_cut->set_contract( is_central_purchasing_contract = VALUE #( document_number = '123'
                                                                                                   header_distributions  = VALUE #( ( data-purchasingdocument = '123' data-distributionnumber = '1' data-deliveryaddresstype = 'ABC' ) ) ) ).

    mo_cut->set_contract( is_central_purchasing_contract = VALUE #( document_number = '123'
                                                                                                   header_distributions  = VALUE #( ( data-purchasingdocument = '123' data-distributionnumber = '2' ) ) ) ).

    mo_cut->set_contract( is_central_purchasing_contract = VALUE #( document_number = '123'
                                                                                                   header_distributions  = VALUE #( ( data-purchasingdocument = '123' data-distributionnumber = '2' data-deliveryaddresstype = 'ABC' )
                                                                                                                                    ( data-purchasingdocument = '123' data-distributionnumber = '3' ) ) ) ).

    " item
    mo_cut->set_contract( is_central_purchasing_contract = VALUE #( document_number = '123'
                                                                                                   items = VALUE #( ( data-ebeln = '123' data-ebelp = '00010' ) ) ) ).
    " item
    mo_cut->set_contract( is_central_purchasing_contract = VALUE #( document_number = '123'
                                                                                                   items = VALUE #( ( data-ebeln = '123' data-ebelp = '00010' data-wepos = '12'  ) ) ) ).
    " item
    mo_cut->set_contract( is_central_purchasing_contract = VALUE #( document_number = '123'
                                                                                                   items = VALUE #( ( data-ebeln = '123' data-ebelp = '00020' ) ) ) ).

    " item distribution
    mo_cut->set_contract( is_central_purchasing_contract = VALUE #( document_number = '123'
                                                                                                   items = VALUE #( (
                                                                                                   item_distribution = VALUE #( ( data-purchasingdocument = '123' data-purchasingdocumentitem = '00010' data-distributionnumber = '1' ) ) ) ) ) ).
    " item distribution
    mo_cut->set_contract( is_central_purchasing_contract = VALUE #( document_number = '123'
                                                                                                   items = VALUE #( (
                                                                                                   item_distribution = VALUE #( ( data-purchasingdocument = '123' data-purchasingdocumentitem = '00010'
                                                                                                                                  data-distributionnumber = '1' data-deliveryaddresstype = 'ABC')
                                                                                                                                ( data-purchasingdocument = '123' data-purchasingdocumentitem = '00010' data-distributionnumber = '2' ) ) ) ) ) ).
    mo_cut->update_documents( ).
    DATA(lt_contract) = mo_cut->if_mass_ops_cctr_setter_getter~get_contracts( ).
    DATA(ls_contracts) = mo_cut->if_mass_ops_cctr_setter_getter~get_contract( iv_document_number = '123' ).

    mo_cut->generate_logs( iv_business_object = ''
                           it_messages        = VALUE #( (  ) ) ).

    mo_cut->generate_logs( iv_business_object = 'BUS2014'
                           it_messages        = VALUE #( (  ) ) ).

    sy-batch = abap_true.
    mo_cut->generate_logs( iv_business_object = 'BUS2014'
                           it_messages        = VALUE #( ( msgid = |EXL_OPS|
                                                           msgty = 'I'
                                                           msgno = 000 ) ) ).
  ENDMETHOD.

ENDCLASS.

CLASS ltc_message_handler DEFINITION DEFERRED.
CLASS cl_mass_ops_cctr_handler DEFINITION LOCAL FRIENDS ltc_message_handler.

CLASS ltc_message_handler DEFINITION
    FOR TESTING DURATION LONG RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    DATA:
    mo_cut TYPE REF TO cl_mass_ops_cctr_handler.

    METHODS:
        setup,
        test_message_handler FOR TESTING.
ENDCLASS.

CLASS ltc_message_handler IMPLEMENTATION.

  METHOD setup.
    mo_cut = cast #( cl_mass_ops_factory=>get_mass_ops_cctr_instance( ) ).
  ENDMETHOD.

  METHOD test_message_handler.
    mo_cut->_add_msg_to_msg_log( it_messages = VALUE #( ( msgid = |EXL_OPS|
                                                          msgty = 'I'
                                                          msgno = 000 ) ) ).

    mo_cut->_persist_generated_log( ).
  ENDMETHOD.

ENDCLASS.
