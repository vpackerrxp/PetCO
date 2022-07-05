table 80008 "PC Rebates"
{
    ObsoleteState = Removed;
    ObsoleteReason = 'Not Required';
    
    fields
    {
        Field(10;"ILE Reference No.";Integer)
        {
            Editable = false;
        }
         field(20;"Receipt No."; Code[20])
        { 
            Editable = false;         
        }
        field(30;"Receipt Line No."; integer)
        { 
            Editable = false;         
        }

        field(40;"Receipt Transaction Date"; Date)
        {          
            Editable = false;   
        }
        field(50;"Location Code"; Code[10])
        {          
            Editable = false;   
        }
        field(60;"SKU No."; Code[20])
        {          
            editable = false;
        }
        field(70;Description; text[100])
        {          
            FieldClass = FlowField;
            CalcFormula = Lookup(Item.Description WHERE ("No."= FIELD("SKU No.")));
            Editable = false;
        }
        field(80;Brand; text[30])
        {          
            FieldClass = FlowField;
            CalcFormula = Lookup(Item.Brand WHERE ("No."= FIELD("SKU No.")));
            Editable = false;
        }
        field(90;Qty; Decimal)
        {          
            editable = false;
        }

        field(100;"UOM"; Code[10])
        {          
            editable = false;
        }
        field(110;"Qty Per"; Decimal)
        {          
            editable = false;
        }
        field(120;"Original Unit Cost";Decimal)
        {          
            editable = false;   
        }
        field(130;"Rebated Unit Cost";Decimal)
        {          
            editable = false;   
        }
    }
    keys
    {
        key(Key1; "ILE Reference No.")
        {
            Clustered = true;
        }
    }
      
}