INTERFACE if_mass_ops_cctr_setter_getter PUBLIC.

  TYPES:
    BEGIN OF ty_item_distribution,
      data TYPE mmpur_s_cctr_distr_line,
      flag TYPE mmpur_s_cctr_distr_linex,
    END OF ty_item_distribution,

    tt_item_distribution TYPE SORTED TABLE OF ty_item_distribution WITH UNIQUE KEY data-purchasingdocument
                                                                                   data-purchasingdocumentitem
                                                                                   data-distributionnumber,

    BEGIN OF ty_header_distribution,
      data TYPE mmpur_s_cctr_distr_line,
      flag TYPE mmpur_s_cctr_distr_linex,
    END OF ty_header_distribution,

    tt_header_distribution TYPE SORTED TABLE OF ty_header_distribution WITH UNIQUE KEY data-purchasingdocument
                                                                                       data-distributionnumber,

    BEGIN OF ty_item,
      data              TYPE meout_item,
      flag              TYPE meout_itemx,
      item_distribution TYPE tt_item_distribution,
    END OF ty_item,

    tt_item TYPE SORTED TABLE OF ty_item WITH UNIQUE KEY data-ebeln
                                                         data-ebelp,

    BEGIN OF ty_header_struc,
      data TYPE meout_header,
      flag TYPE meout_headerx,
    END OF ty_header_struc,

    BEGIN OF ty_header.
      INCLUDE TYPE ty_header_struc.
  TYPES: header_distributions TYPE tt_header_distribution,
      items                TYPE tt_item,
    END OF ty_header.

  TYPES: BEGIN OF ty_central_purchasing_document,
           document_number TYPE ekko-ebeln.
           INCLUDE TYPE ty_header.
  TYPES:  END OF ty_central_purchasing_document,

  tt_central_purchasing_contract TYPE SORTED TABLE OF ty_central_purchasing_document WITH UNIQUE KEY document_number,

  tt_cctr_range TYPE RANGE OF ekko-ebeln.

  CONSTANTS:
    c_document_category  TYPE bstyp VALUE 'C',
    central_pur_contract TYPE string VALUE 'Central Purchase Contract'.

  METHODS:
    get_contract     IMPORTING iv_document_number TYPE ekko-ebeln
                     RETURNING VALUE(rv_document) TYPE ty_central_purchasing_document,
    get_contracts    RETURNING VALUE(rt_documents)            TYPE tt_central_purchasing_contract,
    set_contract     IMPORTING is_central_purchasing_contract TYPE ty_central_purchasing_document,
    remove_contracts IMPORTING it_contracts TYPE tt_cctr_range.
ENDINTERFACE.
