
open Cil;;

print_string "PTRSAFE backend\n";;

(* Determine if the expression is a pointer variable *)
let rec is_ptr expr =
	match expr with
		|CastE(_,e) -> is_ptr e
		|Lval(lv) -> (match typeOfLval lv with TPtr(_,_) -> true | _ -> false )
		|_->false

let say (fmt : ('a,unit,Pretty.doc) format) loc : 'a = 
  let f d =
    ignore (Pretty.eprintf "%t: %a@!" (fun () -> d_loc () loc) Pretty.insert d);
    Pretty.nil
  in
  Pretty.gprintf f fmt
	
(* couldn't get this as a mutable value into the visitor *)

let badops = ref []

class badAssumeVisitor :cilVisitor = object
	inherit Cil.nopCilVisitor 

	method vstmt stmt =
		(*5ay "Just dump %a@!" d_stmt stmt;*)
		let _ = match stmt.skind with
			| If(exp,_,_,loc)-> begin match exp with
				| BinOp(Eq,e1,e2,_) | BinOp(Ne,e1,e2,_) -> begin
					if (is_ptr e1) && (is_ptr e2) then badops := (exp,loc)::!badops else ()
				end
				| _ -> ()
			end
			|_ -> ()
		in Cil.DoChildren
end;;

let files = List.tl(Array.to_list Sys.argv) in
let _ = Cil.initCIL () in
let check_file bad fname =
	(*let _ = print_string (Printf.sprintf "Checking %s...\n" fname) in*)
	let cil_file = (Frontc.parse fname) () in
	let vis = new badAssumeVisitor in
	let _ = badops := [] in
	let _ = visitCilFile vis cil_file in
	let _ = List.iter (fun (ex,loc) -> ignore(say "Bad one: %a@!" loc d_exp  ex)) (List.rev !badops) in
	bad || (List.length !badops <> 0)
in
if List.fold_left check_file false files then exit 5 else exit 0
;;

