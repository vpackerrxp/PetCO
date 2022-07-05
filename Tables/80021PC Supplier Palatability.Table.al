table 80021 "PC Supplier Palatability" 
{
    fields
    {
        field(10;"Supplier No."; Code[20])
        {
            NotBlank = true;
            TableRelation = Vendor where("No."=filter('SUP-*'));
        }
        field(20;"Reason Code"; Code[30])
        {
            NotBlank = true;
        }
        field(30;"Palatability %"; Decimal)
        {
            MaxValue = 100;
        }
    }
    
    keys
    {
        key(Key1; "Supplier No.","Reason Code")
        {
            Clustered = true;
        }
        key(Key2; "Reason Code")
        {
        }
    }
    trigger OnRename()
    begin
        error('Rename is Invalid');     
    end;
}