CLASS zcl_prvd_nchain_erc20 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .
  PUBLIC SECTION.
    INTERFACES zif_prvd_nchain_erc20.
    "! Network id and contract address needed
    METHODS: constructor IMPORTING iv_network_id         TYPE zprvd_nchain_networkid
                                   iv_smartcontract_addr TYPE zprvd_smartcontract_addr
                                   io_nchain_helper      TYPE REF TO zcl_prvd_nchain_helper
                                   io_vault_helper       TYPE REF TO zcl_prvd_vault_helper.
  PROTECTED SECTION.
    DATA: mcl_nchain_helper TYPE REF TO zcl_prvd_nchain_helper,
          mcl_vault_helper  TYPE REF TO zcl_prvd_vault_helper,
          mv_contract_id    TYPE zcasesensitive_str,
          mv_contract_name  TYPE zcasesensitive_str,
          mv_decimals       TYPE i.

    METHODS get_contract_instance IMPORTING iv_network_id         TYPE zprvd_nchain_networkid
                                            iv_smartcontract_addr TYPE zprvd_smartcontract_addr.
    METHODS add_contract_to_nchain IMPORTING iv_network_id         TYPE zprvd_nchain_networkid
                                             iv_smartcontract_addr TYPE zprvd_smartcontract_addr.
    METHODS convert_decimals_to_uint IMPORTING iv_amount      TYPE zif_prvd_nchain_erc20=>ty_input_amount
                                               iv_decimals    TYPE i
                                     RETURNING VALUE(rv_uint) TYPE f.
ENDCLASS.

CLASS zcl_prvd_nchain_erc20 IMPLEMENTATION.

  METHOD constructor.
    IF io_nchain_helper IS NOT INITIAL.
      mcl_nchain_helper = io_nchain_helper.
    ENDIF.
    IF io_vault_helper IS NOT INITIAL.
      mcl_vault_helper = io_vault_helper.
    ENDIF.
    get_contract_instance( iv_network_id         = iv_network_id
                           iv_smartcontract_addr = iv_smartcontract_addr ).
  ENDMETHOD.

  METHOD zif_prvd_nchain_erc20~transfer.
    DATA: ls_exec_contract_req  TYPE zif_prvd_nchain=>ty_executecontractreq_account,
          ls_param              TYPE STANDARD TABLE OF string WITH EMPTY KEY,
          lv_amount_transferred TYPE f,
          lv_inputs             TYPE string,
          lv_decimals           TYPE i.

    lv_decimals = 18.

    lv_amount_transferred  = convert_decimals_to_uint( iv_amount = iv_amount iv_decimals = lv_decimals ).

    lv_inputs = `["` && iv_recipient && `",` && lv_amount_transferred && `]`.

    /ui2/cl_json=>deserialize( EXPORTING json = lv_inputs
                               CHANGING data = ls_param ).

    "Execute the transfer function of the smart contract to send payment
    ls_exec_contract_req-account_id = iv_account-id.
    ls_exec_contract_req-method = 'transfer'.
    ls_exec_contract_req-params = ls_param.
    ls_exec_contract_req-value = 0.

    rs_txn_ref = mcl_nchain_helper->execute_contract_by_account(
                                      iv_contract_id       = mv_contract_id
                                      iv_exec_contract_req = ls_exec_contract_req ).
  ENDMETHOD.

  METHOD get_contract_instance.
    DATA: lv_contract_id TYPE zcasesensitive_str,
          ls_vault       TYPE zif_prvd_vault=>ty_vault_query,
          ls_wallet_key  TYPE zif_prvd_vault=>ty_vault_keys.

    lv_contract_id = mcl_nchain_helper->get_contract_instance( iv_network_id         = iv_network_id
                                                               iv_smartcontract_addr = iv_smartcontract_addr ).
    IF lv_contract_id IS INITIAL.

      "Retrieve org wallet
      ls_vault = mcl_vault_helper->get_org_vault(  ).
      ls_wallet_key = mcl_vault_helper->get_wallet_vault_key( ls_vault-id  ).
      lv_contract_id = mcl_nchain_helper->add_contract_to_nchain( iv_network_id         = iv_network_id
                                                                  iv_contract_name       = mv_contract_name
                                                                  iv_org_wallet_id      = ls_wallet_key-id
                                                                  iv_contract_type      = 'erc20'
                                                                  iv_smartcontract_addr = iv_smartcontract_addr ).
    ENDIF.
    mv_contract_id = lv_contract_id.
  ENDMETHOD.

  METHOD add_contract_to_nchain.
    DATA: ls_vault            TYPE zif_prvd_vault=>ty_vault_query,
          ls_wallet_key       TYPE zif_prvd_vault=>ty_vault_keys,
          ls_selectedcontract TYPE zif_prvd_nchain=>ty_chainlinkpricefeed_req.

    "Retrieve org wallet
    ls_vault = mcl_vault_helper->get_org_vault( ).
    ls_wallet_key = mcl_vault_helper->get_wallet_vault_key( ls_vault-id ).

    "Setup the smart contract request, include reference to the ABI
    mcl_nchain_helper->smartcontract_factory( EXPORTING iv_smartcontractaddress = iv_smartcontract_addr
                                                            iv_name                  = mv_contract_name
                                                            iv_walletaddress         = ls_wallet_key-id
                                                            iv_nchain_networkid      = iv_network_id
                                                            iv_contracttype          = 'erc20'
                                                  IMPORTING es_selectedcontract      = ls_selectedcontract ).

    mv_contract_id = mcl_nchain_helper->create_contract( iv_smartcontractaddr = iv_smartcontract_addr
                                                              is_contract     = ls_selectedcontract ).
  ENDMETHOD.

  METHOD convert_decimals_to_uint.
    DATA lv_gwei TYPE f.
    lv_gwei = 10 ** iv_decimals.
    rv_uint = iv_amount * lv_gwei.
  ENDMETHOD.

ENDCLASS.
