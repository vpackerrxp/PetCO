table 80030 "PC ASN Tracking"
{
    Caption = 'PC ASN Tracking';
   
    fields
    {
        field(10; ID; Integer)
        {
            Caption = 'ID';
            AutoIncrement = true;
         }
        field(20; "ASN Creation Date/Time"; DateTime)
        {
            Caption = 'ASN Creation Date/Time';
        }
        field(30; "PO No."; Code[20])
        {
            Caption = 'PO No.';
        }
        field(40; "Total Qty"; Integer)
        {
            Caption = 'Total Qty';
        }
        field(50; "Total Weight"; decimal)
        {
            Caption = 'Total Weight';
        }
        field(60;"ASN No."; Code[100])
        {
        }
        
    }
    keys
    {
        key(PK; ID)
        {
            Clustered = true;
        }
    }
}
