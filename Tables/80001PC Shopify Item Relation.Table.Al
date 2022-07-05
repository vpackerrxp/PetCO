table 80001 "PC Shopify Item Relations"
{
   fields
    {
        field(10;"Parent Item No."; Code[20])
        {
            Editable = false;
            NotBlank = true;
            trigger OnValidate()
            var
                item:record Item;
            begin
                if Not Item.get("Parent Item No.") then
                    Error(Strsubstno('Parent Item %1 Does Not Exist',"Parent Item No."));
            end;
        }
        field(20;"Child Item No."; Code[20])
        {
            NotBlank = true;
            trigger OnValidate()
            var
                item:record Item;
            begin
                if Not Item.get("Child Item No.") then
                    Error(Strsubstno('Child Item %1 Does Not Exist',"Child Item No."));
            end;
        }
        field(30;"Child Description"; Text[100])
        {
            FieldClass = FlowField;
            CalcFormula = Lookup(Item.Description WHERE ("No."=FIELD("Child Item No.")));
        }
        field(40;"Child Position"; integer)
        {
        }
        field(50;"Un Publish Child"; Boolean)
        {
            //editable = false;
        }
        field(60;"Move To Parent"; Code[20])
        {
            TableRelation = Item where(Type=Const("Non-Inventory"),"Shopify Item"=const(Shopify));
            trigger OnValidate()
            begin
                If "Move To Parent" = "Parent Item No." then Clear("Move To Parent");       
            end;    
        }
        field(70;"Update Required"; Boolean)
        {
        }
    }
    keys
    {
        key(Key1; "Parent Item No.","Child Item No.")
        {
            Clustered = true;
        }
        key(Key2; "Child Position")
        {
        }
    }
    trigger OnInsert()
    var
        Item:Record Item;
    begin
        If Item.Get("Child Item No.") then 
        begin
            Check_duplicates();
            Item."Is Child Flag" := True;
            Item.Modify(False);
        end;
        If Item.Get("Parent Item No.") then
        begin
            Item."Shopify Update Flag" := True;
            Item.Modify(false);
        end;    
    end;
    trigger OnModify()
    var
        Item:record Item;
    begin
        Check_duplicates();
        If Item.Get("Parent Item No.") then
        begin
            Item."Shopify Update Flag" := True;
            Item.Modify(false);
        end;    
    end;
    trigger OnDelete()
    var
        Item:Record Item;
    begin
       If Item.Get("Child Item No.") then 
        begin
            If Item."Is In Shopify Flag" Then Error('Delete is not possible Child Item still exists in shopify');     
        end
        else
            error('Child Item does not exist');
        If Item.Get("Parent Item No.") then
        begin
            Item."Shopify Update Flag" := True;
            Item.Modify(false);
        end;    
    end;
    trigger OnRename()
    begin
        Error('Rename Not Valid');
    end;
    local procedure Check_duplicates()
    var
         rel:Record "PC Shopify Item Relations";
    begin
        rel.reset;
        rel.Setrange("Child Item No.","Child Item No.");
        rel.Setfilter("Parent Item No.",'<>%1',"Parent Item No.");
        if Rel.Findset then Error('Already defined as child item of %1',Rel."Parent Item No.");                  
     end;
 
}