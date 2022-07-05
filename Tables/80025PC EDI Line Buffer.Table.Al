table 80025 "PC EDI Line Buffer"
{
    DataClassification = ToBeClassified;
    
    fields
    {
        field(10;ID; Integer)
        {
        }
        field(20;"Line No."; Integer)
        {
        }
        field(30;"SKU No."; Code[20])
        {
        }
        field(40;"Order Qty"; Decimal)
        {
        }
        field(50;"UOM"; Code[10])
        {
        }
        field(60;"Unit Price"; Decimal)
        {
        }
    }
   keys
    {
        key(Key1; ID,"Line No.")
        {
            Clustered = true;
        }
    }

    
}