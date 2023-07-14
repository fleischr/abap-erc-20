CLASS zcl_prvd_nchain_erc20 DEFINITION PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_prvd_nchain_erc20.
  "! Network id and contract address needed
    METHODS: constructor IMPORTING iv_network_id TYPE zprvd_nchain_networkid
                                 iv_smartcontract_addr TYPE zprvd_smartcontract_addr
                                 iv_nchain_helper TYPE zcl_prvd_nchain_helper.
  PROTECTED SECTION.
    DATA: mcl_nchain_helper TYPE REF TO zcl_prvd_nchain_helper,
          mv_contract_id TYPE zcasesensitive_str.
          
    METHODS get_contract_instance IMPORTING iv_network_id TYPE zprvd_nchain_networkid
                                            iv_smartcontract_addr TYPE zprvd_smartcontract_addr.
    METHODS add_contract_to_nchain IMPORTING iv_network_id TYPE zprvd_nchain_networkid
                                             iv_smartcontract_addr TYPE zprvd_smartcontract_addr.
ENDCLASS.

CLASS zcl_prvd_nchain_erc20 IMPLEMENTATION.

  METHOD constructor.
    get_contract_instance( iv_network_id         = iv_network_id
                           iv_smartcontract_addr = iv_smartcontract_addr ).
  ENDMETHOD.

  METHOD zif_prvd_nchain_erc20~transfer.
    DATA: ls_exec_contract_req   TYPE zif_prvd_nchain=>ty_executecontractreq_account,
         lt_params table of any.
    "Execute the openMint function of the smart contract to mint a NFT
    ls_exec_contract_req-account_id = ls_account-id.
    ls_exec_contract_req-method = 'transfer'.
    ls_exec_contract_req-params = tab.
    ls_exec_contract_req-value = 0.

    rs_txn_ref = mcl_nchain_helper->execute_contract_by_account(
                                      iv_contract_id       = mv_contract_id
                                      iv_exec_contract_req = ls_exec_contract_req ).
  ENDMETHOD.

  METHOD get_contract_instance.

  ENDMETHOD.

  METHOD add_contract_to_nchain.
  ENDMETHOD.

  method convert_decimals_to_uint.
  ENDMETHOD.

ENDCLASS.