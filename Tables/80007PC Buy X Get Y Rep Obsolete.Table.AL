table 80007 "PC Buy X Get Y REP"
{
      ObsoleteState = Removed;
      ObsoleteReason = 'No Longer Required';

    fields
    {
        field(10;"Buy Item No.";Code[20])
        {
            NotBlank = true;
            TableRelation = Item where(Type=Const(Inventory));       
            trigger OnValidate()
            var 
                Item:Record Item;
            begin
                Item.get("Buy Item No.");
                If Item.Type <> Item.Type::Inventory then
                    Error('Must be Inventory Type Item');
                if "Buy Item No." = "Get Item No." then
                    Error('Buy and Get Item No. Can''t Be The Same')
            end;    
        }
        field(15;"Buy Item Qty";Integer)
        {
            MinValue = 1;
            InitValue = 1;
        }

        field(20;"Get Item No.";Code[20])
        {
            NotBlank = true;
            TableRelation = Item where(Type=Const(Inventory));   
            trigger OnValidate()
            var 
                Item:Record Item;
             begin
                Item.get("Buy Item No.");
                If Item.Type <> Item.Type::Inventory then
                    Error('Must be Inventory Type Item');
               if "Buy Item No." = "Get Item No." then
                    Error('Buy and Get Item No. Can''t Be The Same')
            end;    
        }
        field(25;"Get Item Qty";Integer)
        {
            MinValue = 1;
            InitValue = 1;
        }
        field(30;"Get Item Disc %";Decimal)
        {
            MaxValue = 100;
        }
        field(40;"Promotion Start Date";Date)
        {
            trigger OnValidate()
            begin
                If ("Promotion End Date" <> 0D) and ("Promotion Start Date" > "Promotion End Date") then
                    error('Invalid Promotion Start Date');
            end;
        }
        field(50;"Promotion End Date";Date)
        {
            trigger OnValidate()
            begin
                If ("Promotion Start Date" <> 0D) and ("Promotion End Date" <> 0D) AND ("Promotion Start Date" > "Promotion End Date") then
                    error('Invalid Promotion End Date');
            end;
        }
    }
    keys
    {
        key(Key1; "Buy Item No.","Buy Item Qty","Get Item No.","Get Item Qty","Promotion Start Date")
        {
            Clustered = true;
        }
    }
    trigger OnInsert()
    begin
        If "Get Item Disc %" = 0 then
            Error('Get Y Discount Zero is Not valid')
        Else If "Promotion Start Date" = 0D then
            Error('Must Define A Promotion Start Date');        
    end;
    
    trigger OnModify()
    begin
        If "Get Item Disc %" = 0 then
            Error('Get Y Discount Zero is Not valid')    
        Else If "Promotion Start Date" = 0D then
            Error('Must Define A Promotion Start Date');        
    end;
   
    trigger OnRename()
    begin
        Error('Rename is Invalid');       
    end;
    
}