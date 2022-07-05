table 80013 "PC Purch Exceptions"
{
    DataClassification = ToBeClassified;
    
    fields
    {
        field(10;"Purchase Order No."; Code[20])
        {
            Editable = false;            
        }
        field(20;"Exception Date"; Date)
        {
            Editable = false;            
        }
        field(30;"Exception Count"; integer)
        {
            Editable = false;            
        }
        field(40;"Not On Order Exception Count"; integer)
        {
            Editable = false;            
        }
        field(50;"Unknown SKU Exception Count"; integer)
        {
            Editable = false;            
        }
        field(60;"EDI Exception Messages";Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("PC EDI Exception Messages" where("Purchase Order No." = field("Purchase Order No.")));
        }
    }
   
    keys
    {
        key(KEY1; "Purchase Order No.")
        {
            Clustered = true;
        }
    }
    
}