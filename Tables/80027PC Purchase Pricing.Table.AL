table 80027 "PC Purchase Pricing"
{
   
    fields
    {
        field(10;"Item No."; Code[20])
        {
            TableRelation = Item where("No."=filter('SKU-*'));
        }
        field(15;Description; Text[100])
        {
            FieldClass = FlowField;
            CalcFormula = Lookup(Item.Description WHERE ("No."=FIELD("Item No.")));
        }
        field(20;"Supplier Code"; Code[20])
        {
            TableRelation = Vendor where ("No."=filter('SUP-*'));
        }
        field(30;"Unit Cost"; decimal)
        {
            MinValue = 0;
        }
        field(40;"Start Date"; date)
        {
            NotBlank = true;
            trigger OnValidate()
            begin
               If ("End Date" <> 0D) and ("Start Date" > "End Date") then
                    error('Invalid Start Date');
            end;
         }
        field(50;"End Date"; Date)
        {
            trigger OnValidate()
            begin 
               if ("Start Date" <> 0D) and ("End Date" <> 0D) AND ("Start Date" > "End Date") then
                    error('Invalid End Date');
            end;        
        }
    }
     keys
    {
        key(Key1; "Item No.","Supplier Code","Start Date")
        {
            Clustered = true;
        }
    }
}