page 80020 "PC Shopify Child Maintenance"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "PC Shopify Item Relations";  
    InsertAllowed = false;
    DeleteAllowed = false;
    Caption = 'Shopify Child Maintenance';
    layout
    {
        area(Content)
        {
            Group(Filter)
            {
                field("Maintence Mode";mode)
                {
                    ApplicationArea = all;
                    Style = Strong;
                    trigger OnValidate()
                    begin 
                        Clear(SkuLst);
                        Clear(sku);
                        SetFilters();      
                    end;
                }
                field("SKU Filter";Sku)
                {
                    ApplicationArea = all;
                    Style = Strong;
                    TableRelation = Item where("Is Child Flag"=Const(True));
                    trigger OnValidate()
                    begin 
                        If not SkuLst.Contains(Sku) then
                            Skulst += SKU + '|';
                        Clear(sku);
                        SetFilters();   
                    end;
                    trigger OnAssistEdit()
                    begin
                        Clear(SkuLst);
                        SetFilters();   
                    end;
                }
                field("Parent Filter";PAR)
                {
                    ApplicationArea = all;
                    Style = Strong;
                    TableRelation = Item where("Shopify Product ID"=Filter(>0));
                    trigger OnValidate()
                    begin 
                        SetFilters();   
                    end;
                    trigger OnAssistEdit()
                    begin
                        Clear(PAR);
                        SetFilters();   
                    end;
                }
            }    
            repeater(GroupName)
            {   
                field("Parent No"; rec."Parent Item No.")
                {
                    ApplicationArea = All;
                    Editable = False;
                    trigger OnDrillDown()
                    var
                        Pg:page "Item Card";
                        Item:Record Item;
                    begin
                        Item.Get(rec."Parent Item No.");    
                        pg.SetRecord(Item);
                        Pg.RunModal();
                        CurrPage.update(false);
                     end;
                }
                field("Item No."; rec."Child Item No.")
                {
                    ApplicationArea = All;
                    Editable = False;
                    trigger OnDrillDown()
                    var
                        Pg:page "Item Card";
                        Item:Record Item;
                    begin
                        Item.Get(rec."Child Item No.");    
                        pg.SetRecord(Item);
                        Pg.RunModal();
                        CurrPage.update(false);
                     end;
                }
                field(Description; rec."Child Description")
                {
                    Editable = False;
                    ApplicationArea = All;
                }
                field("Move To Parent No";Rec."Move To Parent")
                {
                    ApplicationArea = All;
                    Visible = Mode = Mode::MoveTo;
                }
            }
            Group(Footer)
            {
                Field("Record Count";Rec.Count)
                {
                    ApplicationArea = all;
                    Style = Strong;
                }
            }
             
        }
    }
    actions
    {
        area(Processing)
        {
            action(Msg)
            {
                Visible = Mode = Mode::Deletions;
                ApplicationArea = All;
                Caption = 'Shopify Child Deletions';
                Promoted = true;
                PromotedIsBig = true;
                trigger OnAction();
                var
                    Cu:Codeunit "PC Shopify Routines";
                    Win:Dialog;
                    Temp:Record "PC Shopify Item Relations" temporary;
                    Cnt:Integer;
                    Item:record Item;
                begin
                    If Mode = Mode::Deletions then
                    begin 
                        If Confirm('Are You Sure You Wish To Delete All Marked Child Items From Shopify Now?',True) then
                        begin
                            Win.Open('Removing Shopify Child Item #1##############');
                            SetFilters();
                            CurrPage.SetSelectionFilter(rec);
                            temp.DeleteAll(False);
                            If rec.findSet then
                            repeat
                                temp.Copy(Rec);
                                Temp.insert(false);
                            until rec.Next = 0; 
                            Temp.Reset; 
                            Clear(cnt);       
                            If Temp.Findset then
                            begin
                                repeat
                                    Win.update(1,Temp."Child Item No.");
                                    Item.Get(Temp."Child Item No.");
                                    If Cu.Update_Shopify_Child(Item,Mode) then Cnt+=1;
                                    Item.Get(Temp."Parent Item No.");
                                    Item."Shopify Update Flag" := true;
                                    Item.Modify(False);
                                until Temp.Next = 0;
                                Message('%1 out of %2 Shopify Childs Have Be Deleted',Cnt,Temp.Count);
                            end
                            else
                                Message('Nothing Found Marked for Removal');
                            SetFilters();
                            win.Close();    
                        end;
                    end;
                end;    
            }
            action(Msg1)
            {
                Visible = Mode = Mode::Additions;
                ApplicationArea = All;
                Caption = 'Shopify Child Additions';
                Promoted = true;
                PromotedIsBig = True;
                trigger OnAction();
                var
                    Cu:Codeunit "PC Shopify Routines";
                    Win:Dialog;
                    Temp:Record "PC Shopify Item Relations" temporary;
                    Cnt:Integer;
                    Item:record Item;
                begin
                    if Mode = Mode::Additions then
                    begin
                        If Confirm('Are You Sure You Wish To Add All Marked Child Items Into Shopify Now?',True) then
                        begin
                            Win.Open('Adding Shopify Child Item #1##############');
                            SetFilters();
                            CurrPage.SetSelectionFilter(rec);
                            temp.DeleteAll(False);
                            If rec.findSet then
                            repeat
                                temp.Copy(Rec);
                                Temp.insert(false);
                            until rec.Next = 0;
                            Clear(Cnt);         
                            Temp.Reset;         
                            If Temp.Findset then
                            begin
                                repeat
                                    Win.update(1,Temp."Child Item No.");
                                    Item.Get(Temp."Child Item No.");
                                    If Cu.Update_Shopify_Child(Item,Mode) then Cnt+=1;  
                                    Item.Get(Temp."Parent Item No.");
                                    Item."Shopify Update Flag" := true;
                                    Item.Modify(False);
                                until temp.Next = 0;
                                Message('%1 out of %2 Shopify Childs Have Be Added',Cnt,Temp.Count);
                            end    
                            else
                                Message('Nothing Found Marked For Addition');
                            win.close;    
                            SetFilters();
                        end;
                    end;
                end;    
            }
           action(Msg2)
            {
                Visible = Mode = Mode::MoveTo;
                ApplicationArea = All;
                Caption = 'Shopify Move To';
                Promoted = true;
                PromotedIsBig = true;
                trigger OnAction();
                var
                    Cu:Codeunit "PC Shopify Routines";
                    Win:Dialog;
                    Temp:Record "PC Shopify Item Relations" temporary;
                    Cnt:Integer;
                    Item:record Item;
                begin
                    If Mode = Mode::MoveTo then
                    begin 
                        If Confirm('Are You Sure You Wish To Move Child Items To Defined New Parents Now?',True) then
                        begin
                            Win.Open('Moving Shopify Child Item #1############## To Parent Item #2#############');
                            SetFilters();
                            temp.DeleteAll(False);
                            Rec.SetFilter("Move To Parent",'<>%1','');
                            If rec.findSet then
                            repeat
                                temp.Copy(Rec);
                                Temp.insert(false);
                            until rec.Next = 0; 
                            Temp.Reset; 
                            Clear(cnt);       
                            If Temp.Findset then
                            begin
                                repeat
                                    Win.update(1,Temp."Child Item No.");
                                    Win.Update(2,Temp."Move To Parent");
                                    If Cu.Move_Shopify_SKU(Temp) then Cnt+=1;
                                    Item.Get(Temp."Parent Item No.");
                                    Item."Shopify Update Flag" := true;
                                    Item.Modify(False);
                                until Temp.Next = 0;
                                Message('%1 out of %2 Shopify Childs Have Be Moved',Cnt,Temp.Count);
                            end
                            else
                                Message('Nothing Found To Move');
                            SetFilters();
                            win.Close();    
                        end;
                    end;
                end;    
            }
       }
    }
    
    trigger OnOpenPage()
    begin
        SetFilters();
    end;
    trigger OnClosePage()
    begin
        Rec.Modifyall("Move To Parent",'');    
    end;

    var
        Mode:Option Deletions,Additions,MoveTo;
        Sku:Code[20];
        PAR:code[20];
        SkuLst:text;
    local Procedure SetFilters()
    begin
        Rec.Reset;
        If Mode <> Mode::MoveTo then
        begin
            Rec.Modifyall("Move To Parent",'');    
            Rec.Setrange("Un Publish Child",False);
            If Mode = Mode::Additions then Rec.Setrange("Un Publish Child",True)
        end;
        If Skulst <> '' then rec.Setfilter("Child Item No.",Skulst.Remove(Skulst.LastIndexOf('|'),1));
        If PAR <> '' then Rec.Setrange("Parent Item No.",PAR);      
        CurrPage.update(false);   
    end;
}