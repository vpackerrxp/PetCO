table 80018 "PC Fulfilo Inv. Delta Reasons"
{
   
    fields
    {
        field(10;SKU; Code[20])
        {
            Editable = false;
        }
        field(20;"Location Code"; Code[10])
        {
            Editable = false;
        }
        field(30;"Adjusted DateTime"; Datetime)
        {
            Editable = false;
        }
        field(40;"Reason Code"; Code[5])
        {
            Editable = false;
        }
        field(50;"Reason Description"; Text[50])
        {
            Editable = false;
        }
        field(60;"Sub Reason Code"; Code[5])
        {
            Editable = false;
        }
        field(70;"Sub Reason Description"; Text[50])
        {
            Editable = false;
        }
        field(80;"Adjusted Qty"; Decimal)
        {
            Editable = false;
        }
        field(90;"Adjusted In BC"; Boolean)
        {
            Editable = false;
        }
        field(100;"BC Adjustment DateTime"; DateTime)
        {
            Editable = false;
        }
    }
    
    keys
    {
        key(Key1; SKU,"Location Code","Adjusted DateTime")
        {
            Clustered = true;
        }
    }
    
}