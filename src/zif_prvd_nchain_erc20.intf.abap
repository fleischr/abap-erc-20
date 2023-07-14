INTERFACE zif_prvd_nchain_erc20 PUBLIC.

    "!Transfers the ERC from holders address to another
  METHODS: transfer IMPORTING iv_recipient TYPE zprvd_smartcontract_addr
                              iv_account TYPE zif_prvd_nchain=>ty_account OPTIONAL
                    RETURNING VALUE(rs_txn_ref)  TYPE zif_prvd_nchain=>ty_executecontract_resp.

ENDINTERFACE.