INTERFACE if_mass_ops_cctr_handler PUBLIC .
  INTERFACES:
    if_mass_ops_cctr_setter_getter,
    if_mass_ops_document_handler.

  ALIASES:
    set_contract     FOR if_mass_ops_cctr_setter_getter~set_contract,
    get_contract     FOR if_mass_ops_cctr_setter_getter~get_contract,
    get_contracts    FOR if_mass_ops_cctr_setter_getter~get_contracts,
    remove_contracts FOR if_mass_ops_cctr_setter_getter~remove_contracts,
    update_documents FOR if_mass_ops_document_handler~update_document,
    generate_logs    FOR if_mass_ops_document_handler~generate_log.

ENDINTERFACE.
