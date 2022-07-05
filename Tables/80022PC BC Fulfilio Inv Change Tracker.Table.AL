table 80022 "PC BC Fulfilio Inv Chg Tracker"
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
        field(30;"Fulfilio Adjusted DateTime"; Datetime)
        {
            Editable = false;
        }
        field(40;"Reason Code"; Code[5])
        {
            Editable = false;
        }
        field(50;"Adjusted Qty"; Decimal)
        {
            Editable = false;
        }
        field(60;"BC Adjusted DateTime"; DateTime)
        {
            Editable = false;
        }
    }
   
    keys
    {
        key(Key1; SKU,"Location Code","Fulfilio Adjusted DateTime")
        {
            Clustered = true;
        }
    }
    
}