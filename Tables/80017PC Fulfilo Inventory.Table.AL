table 80017 "PC Fulfilo Inventory"
{
    DataClassification = ToBeClassified;
    
    fields
    {
        field(10;SKU; Code[20])
        {    
        }
        field(20;"Location Code"; Code[10])
        {    
        }
        field(30;Qty; decimal)
        {    
        }
     }
    
    keys
    {
        key(Key1; SKU,"Location Code")
        {
            Clustered = true;
        }
    }
}