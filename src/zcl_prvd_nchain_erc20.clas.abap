CLASS zcl_prvd_nchain_erc20 DEFINITION PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_prvd_nchain_erc20.
  "! Network id and contract address needed
    METHODS: constructor IMPORTING iv_network_id TYPE zprvd_nchain_networkid
                                 iv_smartcontract_addr TYPE zprvd_smartcontract_addr
                                 iv_nchain_helper TYPE zcl_prvd_nchain_helper.
  PROTECTED SECTION.
    DATA: mcl_nchain_helper TYPE REF TO zcl_prvd_nchain_helper,
          mcl_vault_helper  TYPE REF TO zcl_prvd_vault_helper,
          mv_contract_id TYPE zcasesensitive_str,
          mv_contract_name TYPE zcasesensitive_str.
          
    METHODS get_contract_instance IMPORTING iv_network_id TYPE zprvd_nchain_networkid
                                            iv_smartcontract_addr TYPE zprvd_smartcontract_addr.
    METHODS add_contract_to_nchain IMPORTING iv_network_id TYPE zprvd_nchain_networkid
                                             iv_smartcontract_addr TYPE zprvd_smartcontract_addr.
    METHODS convert_decimals_to_uint IMPORTING iv_amount TYPE int8
                                               iv_decimals TYPE i
                                     RETURNING VALUE(rv_uint) TYPE decfloat34.
ENDCLASS.

CLASS zcl_prvd_nchain_erc20 IMPLEMENTATION.

  METHOD constructor.
    get_contract_instance( iv_network_id         = iv_network_id
                           iv_smartcontract_addr = iv_smartcontract_addr ).
  ENDMETHOD.

  METHOD zif_prvd_nchain_erc20~transfer.
    DATA: ls_exec_contract_req   TYPE zif_prvd_nchain=>ty_executecontractreq_account,
          lt_params TABLE OF ANY.

    "Execute the transfer function of the smart contract to send payment
    ls_exec_contract_req-account_id = ls_account-id.
    ls_exec_contract_req-method = 'transfer'.
    ls_exec_contract_req-params = tab.
    ls_exec_contract_req-value = 0.

    rs_txn_ref = mcl_nchain_helper->execute_contract_by_account(
                                      iv_contract_id       = mv_contract_id
                                      iv_exec_contract_req = ls_exec_contract_req ).
  ENDMETHOD.

  METHOD get_contract_instance.
    DATA lv_contract_id TYPE zcasesensitive_str.
    lv_contract_id = mcl_nchain_helper->get_contract_instance( iv_network_id        = iv_network_id
                                                              iv_smartcontract_addr = iv_smartcontract_addr ).
    IF lv_contract_id IS INITIAL.
      lv_contract_id = add_contract_to_nchain( iv_network_id         = iv_network_id
                                               iv_smartcontract_addr = iv_smartcontract_addr ).
    ENDIF.
    mv_contract_id = lv_contract_id.
  ENDMETHOD.

  METHOD add_contract_to_nchain.
    DATA: ls_vault               TYPE zif_prvd_vault=>ty_vault_query,
          ls_wallet_key          TYPE zif_prvd_vault=>ty_vault_keys,
          ls_selectedcontract    TYPE zif_prvd_nchain=>ty_chainlinkpricefeed_req.

    "Retrieve org wallet
    ls_vault = mcl_vault_helper->get_org_vault( ).
    ls_wallet_key = mcl_vault_helper->get_wallet_vault_key( ls_vault-id ).

    "Setup the smart contract request, include reference to the ABI
    mcl_prvd_nchain_helper->smartcontract_factory( EXPORTING iv_smartcontractaddress = iv_smartcontract_addr
                                                            iv_name                  = mv_contract_name
                                                            iv_walletaddress         = ls_wallet_key-id
                                                            iv_nchain_networkid      = iv_network_id
                                                            iv_contracttype          = 'erc20'
                                                  IMPORTING es_selectedcontract      = ls_selectedcontract ).

    mv_contract_id = lcl_prvd_nchain_helper->create_contract( iv_smartcontractaddr = p_ctrct
                                                              is_contract          = ls_selectedcontract ).
  ENDMETHOD.

  METHOD convert_decimals_to_uint.
  ENDMETHOD.

ENDCLASS.