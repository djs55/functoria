module Key = Functoria_key
module Cmd = Functoria_command_line

let result_t =
  let pp ppf = function
    | `Error `Exn   -> Fmt.string ppf "error exn"
    | `Error `Parse -> Fmt.string ppf "error parse"
    | `Error `Term  -> Fmt.string ppf "error term"
    | `Help         -> Fmt.string ppf "help"
    | `Version      -> Fmt.string ppf "version"
    | `Ok action    ->
      let pp = Cmd.pp_action Fmt.(Dump.pair bool bool) in
      Fmt.pf ppf "ok %a" pp action
  in
  Alcotest.testable pp (=)

let key = Alcotest.testable Key.pp Key.equal

let test_keys () =
  let k1 =
    Key.(abstract @@ create "foo" Arg.(opt int 1 (info ["foo"])))
  in
  let k2 =
    Key.(abstract @@ create "foo" Arg.(opt int 2 (info ["foo"])))
  in
  let k3 =
    Key.(abstract @@ create "foo" Arg.(opt int 1 (info ["foo"])))
  in
  Alcotest.(check @@ neg key) "different defaults" k1 k2;
  Alcotest.(check @@ key) "same defaults" k1 k3

let test_configure () =
  let extra_term = Cmdliner.(Term.(
      pure (fun xyz cde -> (xyz, cde))
      $ Arg.(value (flag (info ["x"; "xyz"])))
      $ Arg.(value (flag (info ["c"; "cde"])))
    ))
  in
  let result =
    Cmd.parse_args ~name:"name" ~version:"0.2"
      ~configure:extra_term
      ~describe:extra_term
      ~build:extra_term
      ~clean:extra_term
      ~help:extra_term
      [|"name"; "configure"; "--xyz"; "--verbose"|]
  in
  Alcotest.(check result_t) "configure"
    (`Ok (Cmd.Configure { result = (true, false); output = None }))
    result

let test_describe () =
  let extra_term = Cmdliner.(Term.(
      pure (fun xyz cde -> (xyz, cde))
      $ Arg.(value (flag (info ["x"; "xyz"])))
      $ Arg.(value (flag (info ["c"; "cde"])))
    ))
  in
  let result =
    Cmd.parse_args ~name:"name" ~version:"0.2"
      ~configure:extra_term
      ~describe:extra_term
      ~build:extra_term
      ~clean:extra_term
      ~help:extra_term
      [|"name"; "describe"; "--cde";
        "--color=always"; "--dot-command=dot"; "--eval"|]
  in
  Alcotest.(check result_t) "describe"
    (`Ok (Cmd.Describe { result = (false, true);
                         dotcmd = "dot";
                         dot = false;
                         output = None }))
    result

let test_build () =
  let extra_term = Cmdliner.(Term.(
      pure (fun xyz cde -> (xyz, cde))
      $ Arg.(value (flag (info ["x"; "xyz"])))
      $ Arg.(value (flag (info ["c"; "cde"])))
    ))
  in
  let result =
    Cmd.parse_args ~name:"name" ~version:"0.2"
      ~configure:extra_term
      ~describe:extra_term
      ~build:extra_term
      ~clean:extra_term
      ~help:extra_term
      [|"name"; "build"; "--cde"; "-x"; "--color=never"; "-v"; "-v"|]
  in
  Alcotest.(check result_t) "build"
    (`Ok (Cmd.Build (true, true)))
    result

let test_clean () =
  let extra_term = Cmdliner.(Term.(
      pure (fun xyz cde -> (xyz, cde))
      $ Arg.(value (flag (info ["x"; "xyz"])))
      $ Arg.(value (flag (info ["c"; "cde"])))
    ))
  in
  let result =
    Cmd.parse_args ~name:"name" ~version:"0.2"
      ~configure:extra_term
      ~describe:extra_term
      ~build:extra_term
      ~clean:extra_term
      ~help:extra_term
      [|"name"; "clean"|]
  in
  Alcotest.(check result_t) "clean"
    (`Ok (Cmd.Clean (false, false)))
    result

let test_help () =
  let extra_term = Cmdliner.(Term.(
      pure (fun xyz cde -> (xyz, cde))
      $ Arg.(value (flag (info ["x"; "xyz"])))
      $ Arg.(value (flag (info ["c"; "cde"])))
    ))
  in
  let result =
    Cmd.parse_args ~name:"name" ~version:"0.2"
      ~configure:extra_term
      ~describe:extra_term
      ~build:extra_term
      ~clean:extra_term
      ~help:extra_term
      [|"name"; "help"; "--help"; "plain"|]
  in
  Alcotest.(check result_t) "help" `Help result

let test_default () =
  let extra_term = Cmdliner.(Term.(
      pure (fun xyz cde -> (xyz, cde))
      $ Arg.(value (flag (info ["x"; "xyz"])))
      $ Arg.(value (flag (info ["c"; "cde"])))
    ))
  in
  let result =
    Cmd.parse_args ~name:"name" ~version:"0.2"
      ~configure:extra_term
      ~describe:extra_term
      ~build:extra_term
      ~clean:extra_term
      ~help:extra_term
      [|"name"|]
  in
  Alcotest.(check result_t) "default" `Help result

let test_read_full_eval () =
  let check = Alcotest.(check @@ option bool) in
  begin
    check "test" None
      (Cmd.read_full_eval [|"test"|]);

    check "test --eval" (Some true)
      (Cmd.read_full_eval [|"test"; "--eval"|]);

    check "test blah --eval blah" (Some true)
      (Cmd.read_full_eval [|"test"; "blah"; "--eval"; "blah"|]);

    check "test --no-eval" (Some false)
      (Cmd.read_full_eval [|"test"; "--no-eval"|]);

    check "test blah --no-eval blah" (Some false)
      (Cmd.read_full_eval [|"test"; "blah"; "--no-eval"; "blah"|]);

    check "--no-eval test --eval" (Some true)
      (Cmd.read_full_eval [|"--no-eval"; "test"; "--eval"|]);

    check "--eval test --no-eval" (Some false)
      (Cmd.read_full_eval [|"--eval"; "test"; "--no-eval"|]);
  end

let test_generated_header () =
  let expected = "Generated by prog arg1 arg2 (1970-01-01 00:00:00-00:00)." in
  let got =
    Functoria_app.Codegen.generated_header
      ~argv:[|"prog"; "arg1"; "arg2"|]
      ~time:Ptime.epoch
      ()
  in
  Alcotest.check Alcotest.string "generated_header" expected got

let suite = [
  "keys"          , `Quick, test_keys;
  "read_full_eval", `Quick, test_read_full_eval;
  "configure"     , `Quick, test_configure;
  "describe"      , `Quick, test_describe;
  "build"         , `Quick, test_build;
  "clean"         , `Quick, test_clean;
  "help"          , `Quick, test_help;
  "default"       , `Quick, test_default;
  "generated_header", `Quick, test_generated_header;
]

let () = Alcotest.run "functoria" ["core", suite]
