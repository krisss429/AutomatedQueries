select A.Sts_DESCRIPTION, B.Sts_DESCRIPTION, Chh_TSTAMP_H,Usr_LOGIN from Cm_Opt_Chh_CaseHdr_H
inner join Cc_Sys_Etd_EntityDetail_I on Chh_TAG_ID_H=Etd_ID_I
inner join Cm_Sys_Sts_CaseStatus_S A on Chh_TAG_FROM_VALUE_H =A.Sts_ID
inner join Cm_Sys_Sts_CaseStatus_S B on Chh_TAG_TO_VALUE_H =B.Sts_ID
inner join Cc_Opt_Usr_UserLogin_S on Chh_USER_ID_H=Usr_ID
where chh_id_h=(select chh_id from Cm_Opt_Chh_CaseHdr_S where Chh_APPLICATIONNUMBER='L0080762')
and Chh_TAG_ID_H='79831914-879B-4285-A78F-BCEFA7F4A5E7'
order by Chh_TSTAMP_H desc