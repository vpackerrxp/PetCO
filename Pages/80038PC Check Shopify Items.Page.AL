page 80038 "PC Check Shopify Items"
{
    PageType = Worksheet;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Vendor";
    SourceTableTemporary = True;
    Caption = 'Check Shopify Items';
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            Group(Process)
            {
                field("1";'Check Shopify Items')
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    trigger OnDrillDown()
                    var
                        Win:Dialog;
                        Item:record Item;
                        Cnt:Integer;
                        CU:Codeunit "PC Shopify Routines";
                        Rel:record "PC Shopify Item Relations";
                    begin
                        If Confirm('Check Shopify Items Now',True) then
                        begin
                            Win.Open('Checking Parent #1############ Status -> #2#######');
                            if Rec.findset then Rec.DeleteAll(false);
                            Item.Reset;
                            Item.Setrange(Type,Item.Type::"Non-Inventory");
                            Item.Setfilter("No.",'PAR-*');
                            Item.Setfilter("Shopify Product ID",'>0');
                            If Item.findset then
                            repeat
                                win.update(1,Item."No.");
                                Cu.Check_Product_ID(Item,cnt);
                                Rel.reset;
                                Rel.Setrange("Parent Item No.",Item."No.");
                                Rel.Setrange("Un Publish Child",False);
                                if Rel.Findset then
                                    If Cnt <> Rel.Count then
                                    begin
                                        win.update(2,'FAIL');
                                        if not Rec.get(Item."No.") then
                                        begin   
                                            Rec.init;
                                            Rec."No." := Item."No.";
                                            Rec.Priority := Rel.count;
                                            Rec."Statistics Group" := Cnt;
                                            rec."Prices Including VAT" := Item."Is In Shopify Flag";
                                            Rec.Insert(false);
                                            Commit;
                                        end;    
                                    end
                                    else 
                                       win.update(2,'PASS');    
                            until Item.Next = 0;
                            Win.close;
                            CurrPage.update(false);
                        end;
                    end;
                }
                field("2";'Fix Items')
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    trigger OnDrillDown()
                    var
                        Item:record Item;
                        i:Integer;
                        Cnt:Integer;
                        CU:Codeunit "PC Shopify Routines";
                        Rel:record "PC Shopify Item Relations";
                        win:Dialog;
                    begin
                        If Confirm('Fix Shopify Items Now',True) then
                        begin
                            Rec.reset;
                            Rec.Setrange("Prices Including VAT",True);
                            if Rec.findset then
                            repeat
                                Win.Open('Fixing Parent #1############');
                                Clear(i);
                                Rel.Reset;
                                Rel.SetCurrentKey("Child Position");
                                Rel.Setrange("Parent Item No.",Rec."No.");
                                Rel.Setrange("Un Publish Child",False);
                                If rel.FindSet() then
                                begin
                                    Win.Update(1,Rec."No.");
                                    Cnt := Rel.Count;
                                    repeat
                                        Item.get(rel."Child Item No.");
                                        Clear(Item."Shopify Product Variant ID");
                                        Item.modify(false);
                                        Rel."Child Position" := i;
                                        i+=1;
                                        rel.modify(false);
                                    until rel.next = 0;
                                    Item.Get(rec."No.");
                                    Item."Shopify Update Flag" := True;
                                    Item.modify(false);
                                    Cu.Process_Shopify_Items(Item."No.");
                                    Item."Shopify Update Flag" := True;
                                    Item.modify(false);
                                    Cu.Process_Shopify_Items(Item."No.");    
                                    Cu.Check_Product_ID(Item,Cnt);
                                    if Cnt = Rel.Count then rec.Delete(false);
                                end;
                            until rec.next = 0;
                            Win.close;
                            CurrPage.update(false);           
                        end;
                    end;        
                }
            }
            repeater(GroupName)
            {
               field(SKU; rec."No.")
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        pg:page "Item Card";
                        Item:record Item;
                    begin
                        Item.get(rec."No.");
                        pg.SetRecord(Item);
                        Pg.RunModal();
                    end;
                    trigger OnAssistEdit()
                    var
                        rel:record "PC Shopify Item Relations";
                        Item:Record Item;
                        CU:Codeunit "PC Shopify Routines";
                        i:Integer;
                    begin
                        Clear(i);
                        Rel.Reset;
                        Rel.SetCurrentKey("Child Position");
                        Rel.Setrange("Parent Item No.",Rec."No.");
                        Rel.Setrange("Un Publish Child",False);
                        If rel.FindSet() then
                        begin
                            repeat
                                Item.get(rel."Child Item No.");
                                Clear(Item."Shopify Product Variant ID");
                                Item.modify(false);
                                Rel."Child Position" := i;
                                i+=1;
                                rel.modify(false);
                            until rel.next = 0;
                            Cu.Process_Shopify_Items(Rec."No.");
                            Cu.Process_Shopify_Items(Rec."No.");
                            Item.Get(rec."No.");    
                            Message(Cu.Check_Product_ID(Item,i));
                        end;    
                    end;
                }
                field(t1;Rec.Priority)
                 {
                    ApplicationArea = All;
                    Caption = 'Child Count';
                }
                field(t2;Rec."Statistics Group")
                {
                    ApplicationArea = All;
                    Caption = 'Reported Child Count';
                    trigger OnDrillDown()
                    var
                        Cu:Codeunit "PC Shopify Routines";
                        i:Integer;
                        Item:record Item;
                    begin
                        Item.Get(Rec."No.");
                        Message(Cu.Check_Product_ID(Item,i));
                    end;
                }
                field(t3;Rec."Prices Including VAT")
                {
                    ApplicationArea = All;
                    Caption = 'Is In Shopify';
                }

            }
        }
    }

}