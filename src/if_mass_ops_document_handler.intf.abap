INTERFACE if_mass_ops_document_handler PUBLIC .
    METHODS:
        update_document RETURNING VALUE(rt_messages) TYPE bal_t_msg,
        generate_log    IMPORTING iv_business_object TYPE bal_s_log-subobject
                                  it_messages        TYPE bal_t_msg.
ENDINTERFACE.
