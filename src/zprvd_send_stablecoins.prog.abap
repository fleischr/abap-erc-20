REPORT zprvd_send_stablecoins.

CONSTANTS: c_polygon_mumbai TYPE zcasesensitive_str,
           c_celo_alfajores TYPE zcasesensitive_str.

DATA: lcl_prvd_api_helper    TYPE REF TO zcl_prvd_api_helper,
  lcl_prvd_vault_helper  TYPE REF TO zcl_prvd_vault_helper,
  lcl_prvd_nchain_helper TYPE REF TO zcl_prvd_nchain_helper,
  lcl_prvd_nchain_erc20  TYPE REF TO zcl_prvd_nchain_erc20,
  ls_vault               TYPE zif_prvd_vault=>ty_vault_query,
  ls_wallet_key          TYPE zif_prvd_vault=>ty_vault_keys,
  ls_selectedcontract    TYPE zif_prvd_nchain=>ty_chainlinkpricefeed_req,
  lv_contract_id         TYPE zcasesensitive_str,
  lt_accounts            TYPE zif_prvd_nchain=>ty_account_list,
  ls_account             TYPE zif_prvd_nchain=>ty_account,
  tab                    TYPE string_table,
  ls_exec_contract_req   TYPE zif_prvd_nchain=>ty_executecontractreq_account,
  ls_txn_ref             TYPE zif_prvd_nchain=>ty_executecontract_resp,
  ls_txn_details         TYPE zif_prvd_nchain=>ty_basic_txn_details,
  lv_blockexplorer_link  TYPE string,
  lv_txn_id              TYPE string
  lv_blockexplorer_link TYPE string.

PARAMETERS: p_ntwrk TYPE zprvd_nchain_networkid,
            p_erc20 TYPE zprvd_smartcontract_addr,
            p_recp TYPE zprvd_smartcontract_addr.

"Set up Provide API connectivity.
"Connect to ident, vault, and nchain for decentralized id, digital wallets, and smart contract
lcl_prvd_api_helper = NEW zcl_prvd_api_helper( ).
lcl_prvd_api_helper->get_vault_helper( IMPORTING eo_prvd_vault_helper = lcl_prvd_vault_helper ).
lcl_prvd_api_helper->get_nchain_helper( IMPORTING eo_prvd_nchain_helper = lcl_prvd_nchain_helper ).

lcl_prvd_nchain_erc20 = NEW zcl_prvd_nchain_erc20( iv_network_id         = p_ntwrk
                                                   iv_smartcontract_addr = p_erc20
                                                   iv_nchain_helper      = lcl_prvd_nchain_helper
                                                   iv_vault_helper       = lcl_prvd_vault_helper ).


"Retrieve the account we're using for the selected network
lcl_prvd_nchain_helper->get_accounts( IMPORTING et_accounts = lt_accounts ).
READ TABLE lt_accounts WITH KEY network_id = p_ntwrk INTO ls_account.
IF sy-subrc <> 0.
  MESSAGE 'No account found for selected network' TYPE 'E'.
ENDIF.

ls_txn_ref = lcl_prvd_nchain_erc20~zif_prvd_nchain_erc20->transfer( iv_recipient = p_recp
                                                                    iv_account   = ls_account ).

"Monitor the transaction. Polygon L2 and Celo layer 1 are fast. Expect mainnet Ethereum and others to be slower!
ls_txn_details = lcl_prvd_nchain_helper->get_tx_details( iv_ref_number = ls_txn_ref-ref ).
lv_txn_id = ls_txn_details-hash.

CASE p_ntwrk.
  WHEN c_celo_alfajores.
    lv_blockexplorer_link = |https://alfajores.celoscan.io/tx/| & lv_txn_id.
  WHEN c_polygon_mumbai.
    lv_blockexplorer_link = |https://mumbai.polygonscan.com/tx/| & lv_txn_id.
  WHEN OTHERS.
    lv_blockexplorer_link = |Use this transaction hash in your block explorer:| & lv_txn_id.
ENDCASE.

WRITE 'See block explorer'.
NEW-LINE.
WRITE lv_blockexplorer_link.
