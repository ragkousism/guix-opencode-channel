;;; Crate sources for Pi Agent, generated with
;;;   guix import crate --lockfile=Cargo.lock pi_agent_rust
;;; from pi_agent_rust d65b83a.  Do not edit by hand; regenerate instead.
;;;
;;; Guix carries 650 of these 780 already, but its own rust-crates module
;;; cannot be extended from a channel, so the whole closure is repeated here
;;; and looked up through cargo-inputs' #:module argument.

(define-module (gnu packages pi-crates)
  #:use-module (gnu packages)
  #:use-module (guix build-system cargo)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:export (lookup-cargo-inputs))

(define rust-addr2line-0.25.1
  (crate-source "addr2line" "0.25.1"
                "0jwb96gv17vdr29hbzi0ha5q6jkpgjyn7rjlg5nis65k41rk0p8v"))

(define rust-addr2line-0.26.1
  (crate-source "addr2line" "0.26.1"
                "0ymjl1lj3zwc5c5zbjr21c7jzpklj8l04irn76fnf3lzj9vpycar"))

(define rust-adler2-2.0.1
  (crate-source "adler2" "2.0.1"
                "1ymy18s9hs7ya1pjc9864l30wk8p2qfqdi7mhhcc5nfakxbij09j"))

(define rust-aead-0.5.2
  (crate-source "aead" "0.5.2"
                "1c32aviraqag7926xcb9sybdm36v5vh9gnxpn4pxdwjc50zl28ni"))

(define rust-aes-0.8.4
  (crate-source "aes" "0.8.4"
                "1853796anlwp4kqim0s6wm1srl4ib621nm0cl2h3c8klsjkgfsdi"
                #:snippet '(delete-file-recursively "tests")))

(define rust-aes-gcm-0.10.3
  (crate-source "aes-gcm" "0.10.3"
                "1lgaqgg1gh9crg435509lqdhajg1m2vgma6f7fdj1qa2yyh10443"
                #:snippet '(delete-file-recursively "tests")))

(define rust-ahash-0.8.12
  (crate-source "ahash" "0.8.12"
                "0xbsp9rlm5ki017c0w6ay8kjwinwm8knjncci95mii30rmwz25as"))

(define rust-aho-corasick-1.1.4
  (crate-source "aho-corasick" "1.1.4"
                "00a32wb2h07im3skkikc495jvncf62jl6s96vwc7bhi70h9imlyx"))

(define rust-aligned-0.4.3
  (crate-source "aligned" "0.4.3"
                "1186lhb3gb4x6spzw7ff0zcraa8cr9zqk4ldpm5g1vb2ijc0higf"))

(define rust-aligned-vec-0.6.4
  (crate-source "aligned-vec" "0.6.4"
                "16vnf78hvfix5cwzd5xs5a2g6afmgb4h7n6yfsc36bv0r22072fw"))

(define rust-alloca-0.4.0
  (crate-source "alloca" "0.4.0"
                "1x6p4387rz6j7h342kp3b7bgvqzyl9mibf959pkfk9xflrgd19z5"))

(define rust-allocator-api2-0.2.21
  (crate-source "allocator-api2" "0.2.21"
                "08zrzs022xwndihvzdn78yqarv2b9696y67i6h78nla3ww87jgb8"))

(define rust-android-system-properties-0.1.5
  (crate-source "android_system_properties" "0.1.5"
                "04b3wrz12837j7mdczqd95b732gw5q7q66cv4yn4646lvccp57l1"))

(define rust-anes-0.1.6
  (crate-source "anes" "0.1.6"
                "16bj1ww1xkwzbckk32j2pnbn5vk6wgsl3q4p3j9551xbcarwnijb"))

(define rust-anstream-1.0.0
  (crate-source "anstream" "1.0.0"
                "13d2bj0xfg012s4rmq44zc8zgy1q8k9yp7yhvfnarscnmwpj2jl2"))

(define rust-anstyle-1.0.14
  (crate-source "anstyle" "1.0.14"
                "0030szmgj51fxkic1hpakxxgappxzwm6m154a3gfml83lq63l2wl"))

(define rust-anstyle-parse-1.0.0
  (crate-source "anstyle-parse" "1.0.0"
                "03hkv2690s0crssbnmfkr76kw1k7ah2i6s5amdy9yca2n8w7zkjj"))

(define rust-anstyle-query-1.1.5
  (crate-source "anstyle-query" "1.1.5"
                "1p6shfpnbghs6jsa0vnqd8bb8gd7pjd0jr7w0j8jikakzmr8zi20"))

(define rust-anstyle-wincon-3.0.11
  (crate-source "anstyle-wincon" "3.0.11"
                "0zblannm70sk3xny337mz7c6d8q8i24vhbqi42ld8v7q1wjnl7i9"))

(define rust-anyhow-1.0.104
  (crate-source "anyhow" "1.0.104"
                "0w34jjcm02p5g9kvsjr1dvpw0zs2fi7igi6nr414fkm5gz85w2ik"))

(define rust-ar-archive-writer-0.5.1
  (crate-source "ar_archive_writer" "0.5.1"
                "02rlgsw6k2dh3dk616qyrsl939fwznns1cvf9x0jghmrcfxkpfby"))

(define rust-arbitrary-1.4.2
  (crate-source "arbitrary" "1.4.2"
                "1wcbi4x7i3lzcrkjda4810nqv03lpmvfhb0a85xrq1mbqjikdl63"))

(define rust-arboard-3.6.1
  (crate-source "arboard" "3.6.1"
                "1byx6q5iipxkb0pyjp80k7c4akp4n5m7nsmqdbz4n7s9ak0a2j03"))

(define rust-arc-swap-1.9.1
  (crate-source "arc-swap" "1.9.1"
                "01xjlahcya8igdalxmda375lnlhjqwjz0cdqhy0bc1jkyzb1yfka"))

(define rust-arg-enum-proc-macro-0.3.4
  (crate-source "arg_enum_proc_macro" "0.3.4"
                "1sjdfd5a8j6r99cf0bpqrd6b160x9vz97y5rysycsjda358jms8a"))

(define rust-arrayvec-0.7.6
  (crate-source "arrayvec" "0.7.6"
                "0l1fz4ccgv6pm609rif37sl5nv5k6lbzi7kkppgzqzh1vwix20kw"))

(define rust-as-slice-0.2.1
  (crate-source "as-slice" "0.2.1"
                "05j52y1ws8kir5zjxnl48ann0if79sb56p9nm76hvma01r7nnssi"))

(define rust-ascii-1.1.0
  (crate-source "ascii" "1.1.0"
                "05nyyp39x4wzc1959kv7ckwqpkdzjd9dw4slzyjh73qbhjcfqayr"))

(define rust-asn1-rs-0.7.1
  (crate-source "asn1-rs" "0.7.1"
                "0q0ydbjh2cawwic3r9rfk6lyas2qnj6f2aiic5nw5f1bi2b4lqjn"))

(define rust-asn1-rs-derive-0.6.0
  (crate-source "asn1-rs-derive" "0.6.0"
                "0b7fpyjs2kyb2i922br5mbg8rml46rihr8qmcpdyj2a93sdy829i"))

(define rust-asn1-rs-impl-0.2.0
  (crate-source "asn1-rs-impl" "0.2.0"
                "1xv56m0wrwix4av3w86sih1nsa5g1dgfz135lz1qdznn5h60a63v"))

(define rust-ast-grep-core-0.40.5
  (crate-source "ast-grep-core" "0.40.5"
                "0j5lac9a97hacq74mz1klc36pk20s07y1iy1c5z6k2z16if0iffb"))

(define rust-ast-grep-language-0.40.5
  (crate-source "ast-grep-language" "0.40.5"
                "00323hyh6q8y3vpkpn4g618h9ba8flrmdizdndp0ww6k6hdi8774"))

(define rust-ast-node-5.0.0
  (crate-source "ast_node" "5.0.0"
                "155iy0h9f83l175rkqzc0ih6nlh8s34bjw08yif95nm603pjbc1f"))

(define rust-asupersync-0.3.9
  (crate-source "asupersync" "0.3.9"
                "1ziwcz92ccay04b52rkd4y5nw0jqv428h1gykw2ml0g3vhvxzfhw"))

(define rust-async-lock-3.4.2
  (crate-source "async-lock" "3.4.2"
                "04c3xrrdrfrvh9v0ajxrangpy38qi76qq268zslphnxxjqjpy3r9"))

(define rust-async-trait-0.1.89
  (crate-source "async-trait" "0.1.89"
                "1fsxxmz3rzx1prn1h3rs7kyjhkap60i7xvi0ldapkvbb14nssdch"))

(define rust-autocfg-1.5.0
  (crate-source "autocfg" "1.5.0"
                "1s77f98id9l4af4alklmzq46f21c980v13z2r1pcxx6bqgw0d1n0"))

(define rust-av-scenechange-0.14.1
  (crate-source "av-scenechange" "0.14.1"
                "1543y7riwcy4mmsgcalxcm3bnb41hvwiqiz774nbj68fq9vischg"))

(define rust-av1-grain-0.2.5
  (crate-source "av1-grain" "0.2.5"
                "1y3p43i5xncbny0pfh8kw09am3l3mgyg82ln65r3f434443xpzcc"))

(define rust-avif-serialize-0.8.8
  (crate-source "avif-serialize" "0.8.8"
                "0gd5hr9vd2rkf9gn60f39rham6lzn8a4cdy0p57ihrxx0zq84l1p"))

(define rust-backtrace-0.3.76
  (crate-source "backtrace" "0.3.76"
                "1mibx75x4jf6wz7qjifynld3hpw3vq6sy3d3c9y5s88sg59ihlxv"))

(define rust-base64-0.22.1
  (crate-source "base64" "0.22.1"
                "1imqzgh7bxcikp5vx3shqvw9j09g9ly0xr0jma0q66i52r7jbcvj"))

(define rust-base64ct-1.8.3
  (crate-source "base64ct" "1.8.3"
                "01nyyyx84bhwrcc168hn47d8gvz2pzpv3y3lmck7mq4hw5vh3x9a"))

(define rust-better-scoped-tls-1.0.1
  (crate-source "better_scoped_tls" "1.0.1"
                "029nc2l4xbh3la5q8sz54rdr96y7k9hlggvms7p35c8mac92ilkw"))

(define rust-bincode-1.3.3
  (crate-source "bincode" "1.3.3"
                "1bfw3mnwzx5g1465kiqllp5n4r10qrqy88kdlp3jfwnq2ya5xx5i"))

(define rust-bincode-next-3.1.1
  (crate-source "bincode-next" "3.1.1"
                "1g6c73jhg3yhqyq79w4afny6h12zvr16zj757cljkbjkjf12crhx"))

(define rust-bincode-derive-next-3.1.1
  (crate-source "bincode_derive-next" "3.1.1"
                "073x9l2fk04y1lkjic71jpv4bm271jggghj9gr147rivvaqk55a0"))

(define rust-bindgen-0.72.1
  (crate-source "bindgen" "0.72.1"
                "15bq73y3wd3x3vxh3z3g72hy08zs8rxg1f0i1xsrrd6g16spcdwr"))

(define rust-bit-set-0.8.0
  (crate-source "bit-set" "0.8.0"
                "18riaa10s6n59n39vix0cr7l2dgwdhcpbcm97x1xbyfp1q47x008"))

(define rust-bit-vec-0.8.0
  (crate-source "bit-vec" "0.8.0"
                "1xxa1s2cj291r7k1whbxq840jxvmdsq9xgh7bvrxl46m80fllxjy"))

(define rust-bit-field-0.10.3
  (crate-source "bit_field" "0.10.3"
                "1ikhbph4ap4w692c33r8bbv6yd2qxm1q3f64845grp1s6b3l0jqy"))

(define rust-bitflags-2.11.1
  (crate-source "bitflags" "2.11.1"
                "1cvqijg3rvwgis20a66vfdxannjsxfy5fgjqkaq3l13gyfcj4lf4"))

(define rust-bitstream-io-4.10.0
  (crate-source "bitstream-io" "4.10.0"
                "07zxcy47l51k6vsxphzhgcnqyzl21pprs7212687c64s56z01zvy"
                #:snippet '(for-each delete-file-recursively
                                     '("examples" "tests"))))

(define rust-block-buffer-0.10.4
  (crate-source "block-buffer" "0.10.4"
                "0w9sa2ypmrsqqvc20nhwr75wbb5cjr4kkyhpjm1z1lv2kdicfy1h"))

(define rust-block-buffer-0.12.0
  (crate-source "block-buffer" "0.12.0"
                "1glh8w49a7cj0wlkalyn9j605jzf2ss0lg8dqq5xh8cr2q451lyd"))

(define rust-block2-0.6.2
  (crate-source "block2" "0.6.2"
                "1xcfllzx6c3jc554nmb5qy6xmlkl6l6j5ib4wd11800n0n3rvsyd"))

(define rust-borrow-or-share-0.2.4
  (crate-source "borrow-or-share" "0.2.4"
                "0v0nygw2hbzpbzj7lgk5fnvzxssnh1asnm98ii652x0qmm73c2yw"))

(define rust-bstr-1.12.1
  (crate-source "bstr" "1.12.1"
                "1arc1v7h5l86vd6z76z3xykjzldqd5icldn7j9d3p7z6x0d4w133"))

(define rust-built-0.8.0
  (crate-source "built" "0.8.0"
                "0r5f08lpjsr6j5ajkbmd0ymfmajpq8ddbfvi8ji8rx48y88qzbgl"))

(define rust-bumpalo-3.20.2
  (crate-source "bumpalo" "3.20.2"
                "1jrgxlff76k9glam0akhwpil2fr1w32gbjdf5hpipc7ld2c7h82x"))

(define rust-bytecount-0.6.9
  (crate-source "bytecount" "0.6.9"
                "0pinq0n8zza8qr2lyc3yf17k963129kdbf0bwnmvdk1bpvh14n0p"))

(define rust-bytemuck-1.25.0
  (crate-source "bytemuck" "1.25.0"
                "1v1z32igg9zq49phb3fra0ax5r2inf3aw473vldnm886sx5vdvy8"))

(define rust-byteorder-1.5.0
  (crate-source "byteorder" "1.5.0"
                "0jzncxyf404mwqdbspihyzpkndfgda450l0893pz5xj685cg5l0z"))

(define rust-byteorder-lite-0.1.0
  (crate-source "byteorder-lite" "0.1.0"
                "15alafmz4b9az56z6x7glcbcb6a8bfgyd109qc3bvx07zx4fj7wg"))

(define rust-bytes-1.11.1
  (crate-source "bytes" "1.11.1"
                "0czwlhbq8z29wq0ia87yass2mzy1y0jcasjb8ghriiybnwrqfx0y"))

(define rust-bytes-str-0.2.7
  (crate-source "bytes-str" "0.2.7"
                "1cqqgqddks4kxr704pclh489rgkgwahpk7xqgv1q7f706z7baq3w"))

(define rust-camino-1.2.2
  (crate-source "camino" "1.2.2"
                "0j0ayqfbbl8bxg0795ssk1hzkjix3dvl2kk63hdgzf9cd5nscag6"))

(define rust-cargo-platform-0.3.0
  (crate-source "cargo-platform" "0.3.0"
                "1ql5hk96wmb5clqj0i2lccx2xs86yr0crl3qxv9c4myp3x85vgwa"))

(define rust-cargo-metadata-0.23.1
  (crate-source "cargo_metadata" "0.23.1"
                "1sddycfscjy47av3ykzykqgz8zjds0i00gcxs76vw4x1n0bpv67g"))

(define rust-cast-0.3.0
  (crate-source "cast" "0.3.0"
                "1dbyngbyz2qkk0jn2sxil8vrz3rnpcj142y184p9l4nbl9radcip"))

(define rust-castaway-0.2.4
  (crate-source "castaway" "0.2.4"
                "0nn5his5f8q20nkyg1nwb40xc19a08yaj4y76a8q2y3mdsmm3ify"))

(define rust-cc-1.2.60
  (crate-source "cc" "1.2.60"
                "084a8ziprdlyrj865f3303qr0b7aaggilkl18slncss6m4yp1ia3"))

(define rust-cexpr-0.6.0
  (crate-source "cexpr" "0.6.0"
                "0rl77bwhs5p979ih4r0202cn5jrfsrbgrksp40lkfz5vk1x3ib3g"))

(define rust-cfg-if-1.0.4
  (crate-source "cfg-if" "1.0.4"
                "008q28ajc546z5p2hcwdnckmg0hia7rnx52fni04bwqkzyrghc4k"))

(define rust-cfg-aliases-0.2.1
  (crate-source "cfg_aliases" "0.2.1"
                "092pxdc1dbgjb6qvh83gk56rkic2n2ybm4yvy76cgynmzi3zwfk1"))

(define rust-chacha20-0.9.1
  (crate-source "chacha20" "0.9.1"
                "0678wipx6kghp71hpzhl2qvx80q7caz3vm8vsvd07b1fpms3yqf3"
                #:snippet '(delete-file-recursively "tests")))

(define rust-chacha20poly1305-0.10.1
  (crate-source "chacha20poly1305" "0.10.1"
                "0dfwq9ag7x7lnd0znafpcn8h7k4nfr9gkzm0w7sc1lcj451pkk8h"
                #:snippet '(delete-file-recursively "tests")))

(define rust-charmed-bubbles-0.2.0
  (crate-source "charmed-bubbles" "0.2.0"
                "0nsrfgdxjl36yd89ww4bamlzkwrnm7xs2ch2wx4vi6d71zzc9qyg"))

(define rust-charmed-bubbletea-0.2.0
  (crate-source "charmed-bubbletea" "0.2.0"
                "06vwr56ar8zb0lfgi45a1rik4554ccpby0dda494j6dwc1yz9yym"))

(define rust-charmed-bubbletea-macros-0.2.0
  (crate-source "charmed-bubbletea-macros" "0.2.0"
                "09gvbipl0iv7d550sl9kqrnwnmdipdfdx4z3nvvhcjs2shk6vjk6"))

(define rust-charmed-glamour-0.2.0
  (crate-source "charmed-glamour" "0.2.0"
                "1ncnk96h9m3i4xjxlywzzm1vzl7w6ab5w9bbyvhm5yiggi2vf6rz"))

(define rust-charmed-harmonica-0.2.0
  (crate-source "charmed-harmonica" "0.2.0"
                "1xi488h21p80b2p2fl4qghgysgqms79z6zygn5m6rqvmy49lkv2j"))

(define rust-charmed-lipgloss-0.2.0
  (crate-source "charmed-lipgloss" "0.2.0"
                "1lfchw1g8yss23d1gzn3wmpn6ba1zlrcb9j4kslms1c4dm56m655"))

(define rust-chrono-0.4.44
  (crate-source "chrono" "0.4.44"
                "1c64mk9a235271j5g3v4zrzqqmd43vp9vki7vqfllpqf5rd0fwy6"))

(define rust-ciborium-0.2.2
  (crate-source "ciborium" "0.2.2"
                "03hgfw4674im1pdqblcp77m7rc8x2v828si5570ga5q9dzyrzrj2"))

(define rust-ciborium-io-0.2.2
  (crate-source "ciborium-io" "0.2.2"
                "0my7s5g24hvp1rs1zd1cxapz94inrvqpdf1rslrvxj8618gfmbq5"))

(define rust-ciborium-ll-0.2.2
  (crate-source "ciborium-ll" "0.2.2"
                "1n8g4j5rwkfs3rzfi6g1p7ngmz6m5yxsksryzf5k72ll7mjknrjp"))

(define rust-cipher-0.4.4
  (crate-source "cipher" "0.4.4"
                "1b9x9agg67xq5nq879z66ni4l08m6m3hqcshk37d4is4ysd3ngvp"))

(define rust-clang-sys-1.8.1
  ;; TODO REVIEW: Check bundled sources.
  (crate-source "clang-sys" "1.8.1"
                "1x1r9yqss76z8xwpdanw313ss6fniwc1r7dzb5ycjn0ph53kj0hb"))

(define rust-clap-4.6.1
  (crate-source "clap" "4.6.1"
                "0lcf88l7vlg796rrqr7wipbbmfa5sgsgx4211b7xmxxv8dz13nqx"))

(define rust-clap-builder-4.6.0
  (crate-source "clap_builder" "4.6.0"
                "17q6np22yxhh5y5v53y4l31ps3hlaz45mvz2n2nicr7n3c056jki"))

(define rust-clap-complete-4.6.2
  (crate-source "clap_complete" "4.6.2"
                "1jzr2rl2hl7cjyiks16m6haia5a681zg9gyy5f60g2yxrgfa3xrz"))

(define rust-clap-derive-4.6.1
  (crate-source "clap_derive" "4.6.1"
                "1acpz49hi00iv9jkapixjzcv7s51x8qkfaqscjm36rqgf428dkpj"))

(define rust-clap-lex-1.1.0
  (crate-source "clap_lex" "1.1.0"
                "1ycqkpygnlqnndghhcxjb44lzl0nmgsia64x9581030yifxs7m68"))

(define rust-clipboard-win-5.4.1
  (crate-source "clipboard-win" "5.4.1"
                "1m44gqy11rq1ww7jls86ppif98v6kv2wkwk8p17is86zsdq3gq5x"))

(define rust-clru-0.6.3
  (crate-source "clru" "0.6.3"
                "1mb7vx7s8b3xzx7p2frly9w10b7k2yl3lvrpnvcxba0kn6fdjzqr"))

(define rust-cmov-0.5.3
  (crate-source "cmov" "0.5.3"
                "0ipp2fzpcz2z9l4ywks98bd1viwpw81lfd5pdj3sdi0z04ys921z"))

(define rust-cobs-0.3.0
  (crate-source "cobs" "0.3.0"
                "18f0kxxa1fqb8pz2dxwssnhsrvhrs5j4p8xllgin5d7h36sn3a8g"))

(define rust-color-quant-1.1.0
  (crate-source "color_quant" "1.1.0"
                "12q1n427h2bbmmm1mnglr57jaz2dj9apk0plcxw7nwqiai7qjyrx"))

(define rust-colorchoice-1.0.5
  (crate-source "colorchoice" "1.0.5"
                "0w75k89hw39p0mnnhlrwr23q50rza1yjki44qvh2mgrnj065a1qx"))

(define rust-colored-2.2.0
  (crate-source "colored" "2.2.0"
                "0g6s7j2qayjd7i3sivmwiawfdg8c8ldy0g2kl4vwk1yk16hjaxqi"))

(define rust-compact-str-0.7.1
  (crate-source "compact_str" "0.7.1"
                "0gvvfc2c6pg1rwr2w36ra4674w3lzwg97vq2v6k791w30169qszq"))

(define rust-concurrent-queue-2.5.0
  (crate-source "concurrent-queue" "2.5.0"
                "0wrr3mzq2ijdkxwndhf79k952cp4zkz35ray8hvsxl96xrx1k82c"))

(define rust-console-0.16.3
  (crate-source "console" "0.16.3"
                "11zwz1vnfr0nx6dyjx0gjymp8864y5hxwf01ynfd2s8kapsqlknn"))

(define rust-const-oid-0.9.6
  (crate-source "const-oid" "0.9.6"
                "1y0jnqaq7p2wvspnx7qj76m7hjcqpz73qzvr9l2p9n2s51vr6if2"))

(define rust-const-oid-0.10.2
  (crate-source "const-oid" "0.10.2"
                "0p7m286mp8aai4sa72g7ji6qm0d4ns8wg4i4b2hj9p9615zm3vx6"))

(define rust-convert-case-0.10.0
  (crate-source "convert_case" "0.10.0"
                "1fff1x78mp2c233g68my0ag0zrmjdbym8bfyahjbfy4cxza5hd33"))

(define rust-core-foundation-sys-0.8.7
  ;; TODO REVIEW: Check bundled sources.
  (crate-source "core-foundation-sys" "0.8.7"
                "12w8j73lazxmr1z0h98hf3z623kl8ms7g07jch7n4p8f9nwlhdkp"))

(define rust-cpp-demangle-0.5.1
  (crate-source "cpp_demangle" "0.5.1"
                "1vwx8a999mpqywx0736v54909y52x77w1myjsr6cnmpa69630rq6"))

(define rust-cpufeatures-0.2.17
  (crate-source "cpufeatures" "0.2.17"
                "10023dnnaghhdl70xcds12fsx2b966sxbxjq5sxs49mvxqw5ivar"))

(define rust-cpufeatures-0.3.0
  (crate-source "cpufeatures" "0.3.0"
                "00fjhygsqmh4kbxxlb99mcsbspxcai6hjydv4c46pwb67wwl2alb"))

(define rust-cranelift-assembler-x64-0.134.3
  (crate-source "cranelift-assembler-x64" "0.134.3"
                "0b8b8mwh6c8aa0xqf8qgnl6zl652a479c70yxc5cfvd5nwrvslnm"))

(define rust-cranelift-assembler-x64-meta-0.134.3
  (crate-source "cranelift-assembler-x64-meta" "0.134.3"
                "1pcl8pfgxph9kxm1cls4dlaxyzd7dhjimapn60rrw9r2qbj813h7"))

(define rust-cranelift-bforest-0.134.3
  (crate-source "cranelift-bforest" "0.134.3"
                "0zkk65yjz103k4sd2s0s17kh7m1l0inpp9ii7ihjsmnk99fy2342"))

(define rust-cranelift-bitset-0.134.3
  (crate-source "cranelift-bitset" "0.134.3"
                "1cwapw3c3l6p62hlylpwl0rvnfbhyabpzqnr51cjhvdqsiisbg31"))

(define rust-cranelift-codegen-0.134.3
  (crate-source "cranelift-codegen" "0.134.3"
                "16llh74vjm77i9kyj3bzgg6rl564pmzw1dfmb0k9azdm1xy4p7vh"))

(define rust-cranelift-codegen-meta-0.134.3
  (crate-source "cranelift-codegen-meta" "0.134.3"
                "07ifa6j0rx27dvsxd7l9mawq1yikinbaaf8gklfssapnba8whgch"))

(define rust-cranelift-codegen-shared-0.134.3
  (crate-source "cranelift-codegen-shared" "0.134.3"
                "0s8l9596jrzdbdq6car6hf8g1r3a908m61db97yz6jby496df8h5"))

(define rust-cranelift-control-0.134.3
  (crate-source "cranelift-control" "0.134.3"
                "06ncc9ikq5xjvapqr7nkr5lk2bds7lk6vr0q1cbjxxyfqnhhwmk6"))

(define rust-cranelift-entity-0.134.3
  (crate-source "cranelift-entity" "0.134.3"
                "09jmn029vfcb0iwd99jmmjwf4k0fv935nsmnjrzd4568gjqzabmn"))

(define rust-cranelift-frontend-0.134.3
  (crate-source "cranelift-frontend" "0.134.3"
                "0bc4z42i0iwq0hafz7wgxq21f484b7j238j8nf9hdxyv76m0lzm8"))

(define rust-cranelift-isle-0.134.3
  (crate-source "cranelift-isle" "0.134.3"
                "1ds0isrcjz9q9zhn1698d0158vr3smm4911vgzldbvm1pwz00yfg"))

(define rust-cranelift-native-0.134.3
  (crate-source "cranelift-native" "0.134.3"
                "0ww2sl64w6hgxrswbkzhsdc5vdm0lk2igdjdxrkixj23awilzgq5"))

(define rust-cranelift-srcgen-0.134.3
  (crate-source "cranelift-srcgen" "0.134.3"
                "08l90l30ldla5zar6zg4vk209alqlh8v8rprc8g0s7mbf4m7r5zn"))

(define rust-crc32c-0.6.8
  (crate-source "crc32c" "0.6.8"
                "0iwyr3jivcnhylczqgk1rkpp9b46r25vi5dj1y7il29dc8hsyirs"))

(define rust-crc32fast-1.5.0
  (crate-source "crc32fast" "1.5.0"
                "04d51liy8rbssra92p0qnwjw8i9rm9c4m3bwy19wjamz1k4w30cl"))

(define rust-criterion-0.8.2
  (crate-source "criterion" "0.8.2"
                "1wwq9pfildrkqgb5pq3mwmv297kvvsizkx7m6sjzk4i4mar4c04m"))

(define rust-criterion-plot-0.8.2
  (crate-source "criterion-plot" "0.8.2"
                "1si9mrnzgs0123mr6d5pmhxq29rxph2q6pbvwjal6mav9wphmn6q"))

(define rust-crossbeam-deque-0.8.6
  (crate-source "crossbeam-deque" "0.8.6"
                "0l9f1saqp1gn5qy0rxvkmz4m6n7fc0b3dbm6q1r5pmgpnyvi3lcx"))

(define rust-crossbeam-epoch-0.9.20
  (crate-source "crossbeam-epoch" "0.9.20"
                "0gzg0v8in20iajikalg5i5qgpp0m26r426f0fs8nwk953w218s9d"))

(define rust-crossbeam-queue-0.3.12
  (crate-source "crossbeam-queue" "0.3.12"
                "059igaxckccj6ndmg45d5yf7cm4ps46c18m21afq3pwiiz1bnn0g"))

(define rust-crossbeam-utils-0.8.21
  (crate-source "crossbeam-utils" "0.8.21"
                "0a3aa2bmc8q35fb67432w16wvi54sfmb69rk9h5bhd18vw0c99fh"))

(define rust-crossterm-0.29.0
  (crate-source "crossterm" "0.29.0"
                "0yzqxxd90k7d2ac26xq1awsznsaq0qika2nv1ik3p0vzqvjg5ffq"
                #:snippet '(delete-file-recursively "docs")))

(define rust-crossterm-winapi-0.9.1
  (crate-source "crossterm_winapi" "0.9.1"
                "0axbfb2ykbwbpf1hmxwpawwfs8wvmkcka5m561l7yp36ldi7rpdc"))

(define rust-crunchy-0.2.4
  (crate-source "crunchy" "0.2.4"
                "1mbp5navim2qr3x48lyvadqblcxc1dm0lqr0swrkkwy2qblvw3s6"))

(define rust-crypto-common-0.1.7
  (crate-source "crypto-common" "0.1.7"
                "02nn2rhfy7kvdkdjl457q2z0mklcvj9h662xrq6dzhfialh2kj3q"))

(define rust-crypto-common-0.2.1
  (crate-source "crypto-common" "0.2.1"
                "041p8bs680hrg6rhicfifn19cfvybq9aya5i4i0k08d9byqpnwkp"))

(define rust-ctr-0.9.2
  (crate-source "ctr" "0.9.2"
                "0d88b73waamgpfjdml78icxz45d95q7vi2aqa604b0visqdfws83"
                #:snippet '(delete-file-recursively "tests")))

(define rust-ctrlc-3.5.2
  (crate-source "ctrlc" "3.5.2"
                "0qh1lvlr6k58dliqllx1n7mjfwp1mzr607bks3r9m0a5msrgmcg0"))

(define rust-ctutils-0.4.2
  (crate-source "ctutils" "0.4.2"
                "17m2s9jv7i780k26cq2fcyslg0pakv9plwdrmygdwha1hfiiambx"))

(define rust-curve25519-dalek-4.1.3
  (crate-source "curve25519-dalek" "4.1.3"
                "1gmjb9dsknrr8lypmhkyjd67p1arb8mbfamlwxm7vph38my8pywp"))

(define rust-curve25519-dalek-derive-0.1.1
  (crate-source "curve25519-dalek-derive" "0.1.1"
                "1cry71xxrr0mcy5my3fb502cwfxy6822k4pm19cwrilrg7hq4s7l"))

(define rust-darling-0.20.11
  (crate-source "darling" "0.20.11"
                "1vmlphlrlw4f50z16p4bc9p5qwdni1ba95qmxfrrmzs6dh8lczzw"))

(define rust-darling-core-0.20.11
  (crate-source "darling_core" "0.20.11"
                "0bj1af6xl4ablnqbgn827m43b8fiicgv180749f5cphqdmcvj00d"))

(define rust-darling-macro-0.20.11
  (crate-source "darling_macro" "0.20.11"
                "1bbfbc2px6sj1pqqq97bgqn6c8xdnb2fmz66f7f40nrqrcybjd7w"))

(define rust-dashmap-6.1.0
  (crate-source "dashmap" "6.1.0"
                "1kvnw859xvrqyd1lk89na6797yvl5bri4wi9j0viz2a4j54wqhah"))

(define rust-data-encoding-2.10.0
  (crate-source "data-encoding" "2.10.0"
                "1shzipi8igi058fkx9wfiy6prd7d8rahz1lb7d4idw9nfvrf58fp"))

(define rust-debugid-0.8.0
  (crate-source "debugid" "0.8.0"
                "13f15dfvn07fa7087pmacixqqv0lmj4hv93biw4ldr48ypk55xdy"))

(define rust-der-0.7.10
  (crate-source "der" "0.7.10"
                "1jyxacyxdx6mxbkfw99jz59dzvcd9k17rq01a7xvn1dr6wl87hg7"
                #:snippet '(delete-file-recursively "tests")))

(define rust-der-parser-10.0.0
  (crate-source "der-parser" "10.0.0"
                "19n13gjidjcbj23ps6fww322zx8mz4kfs4cvsd6kqnjx84b51nh7"))

(define rust-deranged-0.5.8
  (crate-source "deranged" "0.5.8"
                "0711df3w16vx80k55ivkwzwswziinj4dz05xci3rvmn15g615n3w"))

(define rust-derive-arbitrary-1.4.2
  (crate-source "derive_arbitrary" "1.4.2"
                "0annkmfwfavd978vwwrxvrpykjfdnc3w6q1ln3j7kyfg5pc7nmhy"))

(define rust-derive-builder-0.20.2
  (crate-source "derive_builder" "0.20.2"
                "0is9z7v3kznziqsxa5jqji3ja6ay9wzravppzhcaczwbx84znzah"))

(define rust-derive-builder-core-0.20.2
  (crate-source "derive_builder_core" "0.20.2"
                "1s640r6q46c2iiz25sgvxw3lk6b6v5y8hwylng7kas2d09xwynrd"))

(define rust-derive-builder-macro-0.20.2
  (crate-source "derive_builder_macro" "0.20.2"
                "0g1zznpqrmvjlp2w7p0jzsjvpmw5rvdag0rfyypjhnadpzib0qxb"))

(define rust-derive-more-2.1.1
  (crate-source "derive_more" "2.1.1"
                "0d5i10l4aff744jw7v4n8g6cv15rjk5mp0f1z522pc2nj7jfjlfp"))

(define rust-derive-more-impl-2.1.1
  (crate-source "derive_more-impl" "2.1.1"
                "1jwdp836vymp35d7mfvvalplkdgk2683nv3zjlx65n1194k9g6kr"))

(define rust-diff-0.1.13
  (crate-source "diff" "0.1.13"
                "1j0nzjxci2zqx63hdcihkp0a4dkdmzxd7my4m7zk6cjyfy34j9an"))

(define rust-digest-0.10.7
  (crate-source "digest" "0.10.7"
                "14p2n6ih29x81akj097lvz7wi9b6b9hvls0lwrv7b6xwyy0s5ncy"))

(define rust-digest-0.11.2
  (crate-source "digest" "0.11.2"
                "0g0m77q7zfafm4jgy6i70wwimy9f41ywidbz9w467rh8px4xnl28"
                #:snippet '(delete-file-recursively "tests")))

(define rust-directories-next-2.0.0
  (crate-source "directories-next" "2.0.0"
                "1g1vq8d8mv0vp0l317gh9y46ipqg2fxjnbc7lnjhwqbsv4qf37ik"))

(define rust-dirs-6.0.0
  (crate-source "dirs" "6.0.0"
                "0knfikii29761g22pwfrb8d0nqpbgw77sni9h2224haisyaams63"))

(define rust-dirs-sys-0.5.0
  ;; TODO REVIEW: Check bundled sources.
  (crate-source "dirs-sys" "0.5.0"
                "1aqzpgq6ampza6v012gm2dppx9k35cdycbj54808ksbys9k366p0"))

(define rust-dirs-sys-next-0.1.2
  (crate-source "dirs-sys-next" "0.1.2"
                "0kavhavdxv4phzj4l0psvh55hszwnr0rcz8sxbvx20pyqi2a3gaf"))

(define rust-dispatch2-0.3.1
  (crate-source "dispatch2" "0.3.1"
                "0f5xmnbzpaz1g80m27kd804p75nswh0ikb6wvqh4ba3x9rz3c3hy"))

(define rust-displaydoc-0.2.5
  (crate-source "displaydoc" "0.2.5"
                "1q0alair462j21iiqwrr21iabkfnb13d6x5w95lkdg21q2xrqdlp"))

(define rust-document-features-0.2.12
  (crate-source "document-features" "0.2.12"
                "0qcgpialq3zgvjmsvar9n6v10rfbv6mk6ajl46dd4pj5hn3aif6l"))

(define rust-dragonbox-ecma-0.1.12
  (crate-source "dragonbox_ecma" "0.1.12"
                "1gs6yz1klalmhmvq8wrmxz0cnc41c4xlb7iz5pv7wzn3hh8713px"))

(define rust-dunce-1.0.5
  (crate-source "dunce" "1.0.5"
                "04y8wwv3vvcqaqmqzssi6k0ii9gs6fpz96j5w9nky2ccsl23axwj"))

(define rust-ed25519-2.2.3
  (crate-source "ed25519" "2.2.3"
                "0lydzdf26zbn82g7xfczcac9d7mzm3qgx934ijjrd5hjpjx32m8i"
                #:snippet '(delete-file-recursively "tests")))

(define rust-ed25519-dalek-2.2.0
  (crate-source "ed25519-dalek" "2.2.0"
                "1agcwij1z687hg26ngzwhnmpz29b2w56m8z1ap3pvrnfh709drvh"
                #:snippet '(for-each delete-file-recursively '("docs" "tests"))))

(define rust-either-1.15.0
  (crate-source "either" "1.15.0"
                "069p1fknsmzn9llaizh77kip0pqmcwpdsykv2x30xpjyija5gis8"))

(define rust-email-address-0.2.9
  (crate-source "email_address" "0.2.9"
                "0jf4v3npa524c7npy7w3jl0a6gng26f51a4bgzs3jqna12dz2yg0"))

(define rust-embedded-io-0.4.0
  (crate-source "embedded-io" "0.4.0"
                "1v9wrc5nsgaaady7i3ya394sik5251j0iq5rls7mrx7fv696h6pg"))

(define rust-embedded-io-0.6.1
  (crate-source "embedded-io" "0.6.1"
                "0v901xykajh3zffn6x4cnn4fhgfw3c8qpjwbsk6gai3gaccg3l7d"))

(define rust-enable-ansi-support-0.2.1
  (crate-source "enable-ansi-support" "0.2.1"
                "0q5wv5b9inh7kzc2464ch51ffk920f9yb0q9xvvlp9cs5apg6kxa"))

(define rust-encode-unicode-1.0.0
  (crate-source "encode_unicode" "1.0.0"
                "1h5j7j7byi289by63s3w4a8b3g6l5ccdrws7a67nn07vdxj77ail"))

(define rust-encoding-rs-0.8.35
  (crate-source "encoding_rs" "0.8.35"
                "1wv64xdrr9v37rqqdjsyb8l8wzlcbab80ryxhrszvnj59wy0y0vm"))

(define rust-equator-0.4.2
  (crate-source "equator" "0.4.2"
                "1z760z5r0haxjyakbqxvswrz9mq7c29arrivgq8y1zldhc9v44a7"))

(define rust-equator-macro-0.4.2
  (crate-source "equator-macro" "0.4.2"
                "1cqzx3cqn9rxln3a607xr54wippzff56zs5chqdf3z2bnks3rwj4"))

(define rust-equivalent-1.0.2
  (crate-source "equivalent" "1.0.2"
                "03swzqznragy8n0x31lqc78g2af054jwivp7lkrbrc0khz74lyl7"))

(define rust-errno-0.3.14
  (crate-source "errno" "0.3.14"
                "1szgccmh8vgryqyadg8xd58mnwwicf39zmin3bsn63df2wbbgjir"))

(define rust-error-code-3.3.2
  (crate-source "error-code" "3.3.2"
                "0nacxm9xr3s1rwd6fabk3qm89fyglahmbi4m512y0hr8ym6dz8ny"))

(define rust-event-listener-5.4.2
  (crate-source "event-listener" "5.4.2"
                "1lk9sv7r07l58jk263s18896l55mx9jv0g1rm4hj2mpi3paas8ss"))

(define rust-event-listener-strategy-0.5.4
  (crate-source "event-listener-strategy" "0.5.4"
                "14rv18av8s7n8yixg38bxp5vg2qs394rl1w052by5npzmbgz7scb"))

(define rust-exr-1.74.0
  (crate-source "exr" "1.74.0"
                "1gk3cc2qkfm0jqw4v1d7g4c356k9iz583bq17iiwp8kalm1y0023"))

(define rust-fancy-regex-0.17.0
  (crate-source "fancy-regex" "0.17.0"
                "1f314z64ilbbnn17ic1hghpq9dm2sqyn8gspvjvjp1jwhqgldkvj"))

(define rust-faster-hex-0.10.0
  (crate-source "faster-hex" "0.10.0"
                "0wzvv4a1czxfxmh99cza2y0jps97hm3k1j6r6cs816qp5wnsw8vj"))

(define rust-fastrand-2.4.1
  (crate-source "fastrand" "2.4.1"
                "1mnqxxnxvd69ma9mczabpbbsgwlhd6l78yv3vd681453a9s247wz"))

(define rust-fax-0.2.6
  (crate-source "fax" "0.2.6"
                "1ax0jmvsszxd03hj6ga1kyl7gaqcfw0akg2wf0q6gk9pizaffpgh"))

(define rust-fax-derive-0.2.0
  (crate-source "fax_derive" "0.2.0"
                "0zap434zz4xvi5rnysmwzzivig593b4ng15vwzwl7js2nw7s3b50"))

(define rust-fdeflate-0.3.7
  (crate-source "fdeflate" "0.3.7"
                "130ga18vyxbb5idbgi07njymdaavvk6j08yh1dfarm294ssm6s0y"
                #:snippet '(delete-file-recursively "tests")))

(define rust-fiat-crypto-0.2.9
  (crate-source "fiat-crypto" "0.2.9"
                "07c1vknddv3ak7w89n85ik0g34nzzpms6yb845vrjnv9m4csbpi8"))

(define rust-filetime-0.2.27
  (crate-source "filetime" "0.2.27"
                "1nspbkm1d1km7xfljcbl565swqxrihqyin8bqppig2gf3qal927r"))

(define rust-find-msvc-tools-0.1.9
  (crate-source "find-msvc-tools" "0.1.9"
                "10nmi0qdskq6l7zwxw5g56xny7hb624iki1c39d907qmfh3vrbjv"))

(define rust-fixedbitset-0.4.2
  (crate-source "fixedbitset" "0.4.2"
                "101v41amgv5n9h4hcghvrbfk5vrncx1jwm35rn5szv4rk55i7rqc"))

(define rust-flate2-1.1.9
  (crate-source "flate2" "1.1.9"
                "0g2pb7cxnzcbzrj8bw4v6gpqqp21aycmf6d84rzb6j748qkvlgw4"
                #:snippet '(for-each delete-file-recursively '("examples" "tests"))))

(define rust-fluent-uri-0.4.1
  (crate-source "fluent-uri" "0.4.1"
                "13ij9dqj3hnv8029293i6j7wzr8rjqh15m866mi71bjrhd6sqx5w"))

(define rust-fnv-1.0.7
  (crate-source "fnv" "1.0.7"
                "1hc2mcqha06aibcaza94vbi81j6pr9a1bbxrxjfhc91zin8yr7iz"))

(define rust-foldhash-0.1.5
  (crate-source "foldhash" "0.1.5"
                "1wisr1xlc2bj7hk4rgkcjkz3j2x4dhd1h9lwk7mj8p71qpdgbi6r"))

(define rust-foldhash-0.2.0
  (crate-source "foldhash" "0.2.0"
                "1nvgylb099s11xpfm1kn2wcsql080nqmnhj1l25bp3r2b35j9kkp"))

(define rust-form-urlencoded-1.2.2
  (crate-source "form_urlencoded" "1.2.2"
                "1kqzb2qn608rxl3dws04zahcklpplkd5r1vpabwga5l50d2v4k6b"))

(define rust-fraction-0.15.4
  (crate-source "fraction" "0.15.4"
                "0wmqlp84vn9q4vmjvbhd3min6x2wyg508pzd6d9l7b1xnidh8xp0"))

(define rust-franken-decision-0.3.9
  (crate-source "franken-decision" "0.3.9"
                "1c3y0fjskci7h1rpjky0bgjinp0iplab4iribcy3w5wcqs2a4fvn"))

(define rust-franken-evidence-0.3.9
  (crate-source "franken-evidence" "0.3.9"
                "1n4db1wa1bqsfah3b1hqmvxjl64giq8lyxhynxrpl0sbzsriv93w"))

(define rust-franken-kernel-0.3.9
  (crate-source "franken-kernel" "0.3.9"
                "1ciwdmxbnrjzvs58cp8x463h9fhhnj3ikhdk2qivmdz2fkrpbkgp"))

(define rust-from-variant-3.0.0
  (crate-source "from_variant" "3.0.0"
                "1aay6hgrcyyhkglhcq8a8rirygcv4s8dch031894kydfj6ikbzz5"))

(define rust-fs4-0.13.1
  (crate-source "fs4" "0.13.1"
                "1m0y2kmwzifkrivw7gjav0km5s9agaiv324yrq424rgpi15y6h46"))

(define rust-futures-0.3.32
  (crate-source "futures" "0.3.32"
                "0b9q86r5ar18v5xjiyqn7sb8sa32xv98qqnfz779gl7ns7lpw54b"))

(define rust-futures-channel-0.3.32
  (crate-source "futures-channel" "0.3.32"
                "07fcyzrmbmh7fh4ainilf1s7gnwvnk07phdq77jkb9fpa2ffifq7"))

(define rust-futures-core-0.3.32
  (crate-source "futures-core" "0.3.32"
                "07bbvwjbm5g2i330nyr1kcvjapkmdqzl4r6mqv75ivvjaa0m0d3y"))

(define rust-futures-executor-0.3.32
  (crate-source "futures-executor" "0.3.32"
                "17aplz3ns74qn7a04qg7qlgsdx5iwwwkd4jvdfra6hl3h4w9rwms"))

(define rust-futures-io-0.3.32
  (crate-source "futures-io" "0.3.32"
                "063pf5m6vfmyxj74447x8kx9q8zj6m9daamj4hvf49yrg9fs7jyf"))

(define rust-futures-lite-2.6.1
  (crate-source "futures-lite" "2.6.1"
                "1ba4dg26sc168vf60b1a23dv1d8rcf3v3ykz2psb7q70kxh113pp"))

(define rust-futures-macro-0.3.32
  (crate-source "futures-macro" "0.3.32"
                "0ys4b1lk7s0bsj29pv42bxsaavalch35rprp64s964p40c1bfdg8"))

(define rust-futures-sink-0.3.32
  (crate-source "futures-sink" "0.3.32"
                "14q8ml7hn5a6gyy9ri236j28kh0svqmrk4gcg0wh26rkazhm95y3"))

(define rust-futures-task-0.3.32
  (crate-source "futures-task" "0.3.32"
                "14s3vqf8llz3kjza33vn4ixg6kwxp61xrysn716h0cwwsnri2xq3"))

(define rust-futures-util-0.3.32
  (crate-source "futures-util" "0.3.32"
                "1mn60lw5kh32hz9isinjlpw34zx708fk5q1x0m40n6g6jq9a971q"))

(define rust-fxprof-processed-profile-0.8.1
  (crate-source "fxprof-processed-profile" "0.8.1"
                "0mx5xnbx8ph2zy6asx74lqlvag7hxhwzw33pc4m9c2pclch4y8r5"))

(define rust-generator-0.8.8
  (crate-source "generator" "0.8.8"
                "1ybcxxz9vdh7nyh9q5654zv5q790b63a83w0zrv0r8id2pj4mw2j"))

(define rust-generic-array-0.14.7
  (crate-source "generic-array" "0.14.7"
                "16lyyrzrljfq424c3n8kfwkqihlimmsg5nhshbbp48np3yjrqr45"))

(define rust-gethostname-1.1.0
  (crate-source "gethostname" "1.1.0"
                "1n6bj9gh503ggjblfjcai96gmxynxsrykaynljlrfdra34q95m0v"))

(define rust-getopts-0.2.24
  (crate-source "getopts" "0.2.24"
                "1pylvsmq7fillnxmd6g58r7igdrlby412q37ws41z39va2ngpr6g"))

(define rust-getrandom-0.2.17
  (crate-source "getrandom" "0.2.17"
                "1l2ac6jfj9xhpjjgmcx6s1x89bbnw9x6j9258yy6xjkzpq0bqapz"))

(define rust-getrandom-0.3.4
  (crate-source "getrandom" "0.3.4"
                "1zbpvpicry9lrbjmkd4msgj3ihff1q92i334chk7pzf46xffz7c9"))

(define rust-getrandom-0.4.2
  (crate-source "getrandom" "0.4.2"
                "0mb5833hf9pvn9dhvxjgfg5dx0m77g8wavvjdpvpnkp9fil1xr8d"))

(define rust-ghash-0.5.1
  (crate-source "ghash" "0.5.1"
                "1wbg4vdgzwhkpkclz1g6bs4r5x984w5gnlsj4q5wnafb5hva9n7h"))

(define rust-gif-0.14.2
  (crate-source "gif" "0.14.2"
                "0n81js7vlb9bwrjb765sicza3k0vrihjddrgm2mvpbfr272gr37f"))

(define rust-gimli-0.32.3
  (crate-source "gimli" "0.32.3"
                "1iqk5xznimn5bfa8jy4h7pa1dv3c624hzgd2dkz8mpgkiswvjag6"))

(define rust-gimli-0.33.0
  (crate-source "gimli" "0.33.0"
                "0v0jgyxdakhn8z74dvm9l38a0bwvfhrc9b3wiigq0ncmz11z1xqb"))

(define rust-gix-0.77.0
  (crate-source "gix" "0.77.0"
                "1k3q5cydhxkaxizgvx8qbaph9k0mi099l8gpzf3hjp1gdbc890ix"))

(define rust-gix-actor-0.37.1
  (crate-source "gix-actor" "0.37.1"
                "1i2mm9yq55xydcn2kq4l6sap62b8lkhmypsh1z953asy826m4if3"))

(define rust-gix-attributes-0.29.0
  (crate-source "gix-attributes" "0.29.0"
                "0rjr27v9dg7dnh1yyyw9mj3jzwn4qx0895sxlp1mh58glpwanzgl"))

(define rust-gix-bitmap-0.2.16
  (crate-source "gix-bitmap" "0.2.16"
                "1qj1pxxqb97ja6jdms17b86wcx5f3laadlnha6c6d3k0y1zgr0nr"))

(define rust-gix-chunk-0.4.12
  (crate-source "gix-chunk" "0.4.12"
                "1swf50dk3i9gbq8bsg25hkhj2658261vnlcmazzvcz374lw6ndaw"))

(define rust-gix-command-0.6.5
  (crate-source "gix-command" "0.6.5"
                "0r2wil9m2h954z89ckldid7q18cvqv1shv8y6lslhr8afcjw9ya6"))

(define rust-gix-commitgraph-0.31.0
  (crate-source "gix-commitgraph" "0.31.0"
                "0fp6mf271lpvlwi5w91hs61n2gkwb6fr9bsx48asynq4920bmp7g"))

(define rust-gix-config-0.50.0
  (crate-source "gix-config" "0.50.0"
                "013lqvx6knlvlb2mqz02fkrsyp27l0ng0q72qpr72szrxvw2z3mm"))

(define rust-gix-config-value-0.16.0
  (crate-source "gix-config-value" "0.16.0"
                "0h4qwzymmb0cx9sf8ppw0b9nbfm9kpgshssvgn207cz89zxcy294"))

(define rust-gix-date-0.12.1
  (crate-source "gix-date" "0.12.1"
                "1ryqz14al79806pfcrrzb6gg3iiyzpjx4w7sjhq277hmp2x32jpy"))

(define rust-gix-diff-0.57.1
  (crate-source "gix-diff" "0.57.1"
                "142fkcjsjwf21g63h8hwykwjxfa3irnd13pjnmacs56fcdp961im"))

(define rust-gix-dir-0.19.0
  (crate-source "gix-dir" "0.19.0"
                "01hya3ifj8vc6m0hqzl7snv03s39clj78245540qpsyj6anrz7bh"))

(define rust-gix-discover-0.45.0
  (crate-source "gix-discover" "0.45.0"
                "1pjrngnkj0hdkvkf5ps1hc1z4n4803adavwxl013hlrjq5nhkkj2"))

(define rust-gix-features-0.45.2
  (crate-source "gix-features" "0.45.2"
                "1lb0fn89xbzk7anila7izhyjbijackgk6l3h6ja485p0g8ssssnm"))

(define rust-gix-filter-0.24.1
  (crate-source "gix-filter" "0.24.1"
                "1p15k9ica0idcrs80gl09x8r2hwcc0d4bbcl3w65g0i4jrj29h0h"))

(define rust-gix-fs-0.18.2
  (crate-source "gix-fs" "0.18.2"
                "1v2rsd8cw6gdasl2krwy6xaqd8gwnchqq50wp3bpig26kr4rqnvq"))

(define rust-gix-glob-0.23.0
  (crate-source "gix-glob" "0.23.0"
                "1qmp2942iaa6wl6vda3199jrp9i424r3wan2c9c5rip4mq066m78"))

(define rust-gix-hash-0.21.2
  (crate-source "gix-hash" "0.21.2"
                "0kbiwz55c3lbs5sc9l3ck6lgcya8ab6jf43b62ivinnc887r6lz1"))

(define rust-gix-hashtable-0.11.0
  (crate-source "gix-hashtable" "0.11.0"
                "1w6j5dh5mfvgw4m8b69z36rmzgs8x8rxhzm8fbrbw830ccl78br2"))

(define rust-gix-ignore-0.18.0
  (crate-source "gix-ignore" "0.18.0"
                "088vp0jkxb1wbwavydp3x1rk0b8p2xf1mfrzz99zpnagypyjg9yz"))

(define rust-gix-index-0.45.1
  (crate-source "gix-index" "0.45.1"
                "0l90yibnjkh9v55glhzzfll6vk4l4iwa1pj1yi4vliqnw7lx79ly"))

(define rust-gix-lock-20.0.1
  (crate-source "gix-lock" "20.0.1"
                "1i9s3al7yiimbnj8qca5ir2wmb05xvn0w9kpzk3pnfrvbsp6hlhi"))

(define rust-gix-object-0.54.1
  (crate-source "gix-object" "0.54.1"
                "10dws3l802w6iqvalz40gq5zsr53r7cagzz0h00qkr2jkj3nlg9n"))

(define rust-gix-odb-0.74.0
  (crate-source "gix-odb" "0.74.0"
                "1if0pj83vya9hvnv9b6g13dsm5z5gapqpbqg6ga2x8b9ydyr0nhn"))

(define rust-gix-pack-0.64.1
  (crate-source "gix-pack" "0.64.1"
                "0rj3rn4jqfpf9lwl1qccmijy6djfybk0lb2ywnm0zsh7mgap6jmh"))

(define rust-gix-packetline-0.20.0
  (crate-source "gix-packetline" "0.20.0"
                "0cfyqywjrpahn0v14hx5597p5b6b97ld6rd1hy08i2d2hawzzl7s"))

(define rust-gix-path-0.10.22
  (crate-source "gix-path" "0.10.22"
                "0rpksdgf0wv6w6x6irx09qgm32p28lqsjpwizlj6xvcf9wz6rc3w"))

(define rust-gix-pathspec-0.14.0
  (crate-source "gix-pathspec" "0.14.0"
                "1180p6g85ng1axvc7d20s8x7njlwfz2xd22jyiz7mhrk3640r7pd"))

(define rust-gix-protocol-0.55.0
  (crate-source "gix-protocol" "0.55.0"
                "01sd7wv297bl2c5by4csq3r6a5w55ps2ww4yf32l553qd38dzi82"))

(define rust-gix-quote-0.6.2
  (crate-source "gix-quote" "0.6.2"
                "0mv7qgy955378bf163c1qagn20pb00gsnbph0wlckh4cxkr2zz4n"))

(define rust-gix-ref-0.57.0
  (crate-source "gix-ref" "0.57.0"
                "0qwarw34p0rmvxn41c6ldz8jxc36k9b37qpxhfg7xqq6f2lkmcyc"))

(define rust-gix-refspec-0.35.0
  (crate-source "gix-refspec" "0.35.0"
                "00nsaxgnhg8xa8jlns5vx2qpvkmajm0jmmm2fcgh5x49afpadfyw"))

(define rust-gix-revision-0.39.0
  (crate-source "gix-revision" "0.39.0"
                "1j64xcsqjxk7yn0rby1g08w2z9blz8f1fp9myyb5cqwcn61qr2ci"))

(define rust-gix-revwalk-0.25.0
  (crate-source "gix-revwalk" "0.25.0"
                "1clyjjbgs1mz2ybkg2cspbld57v0nw6vplnhcdl031c44yckc1hd"))

(define rust-gix-sec-0.12.2
  (crate-source "gix-sec" "0.12.2"
                "1gm6zwymkb03i64a41xmbci3qa215xskiq7g03qzf54idpnn56ga"))

(define rust-gix-shallow-0.7.0
  (crate-source "gix-shallow" "0.7.0"
                "0mi3hdaikiy4rn9sf8l29fwbq5755m4aabiwc4rivv7pp5zlc74w"))

(define rust-gix-status-0.24.0
  (crate-source "gix-status" "0.24.0"
                "1llnjsxbqn6q0357gwywa0zj730f6lpw4m2lr9wwccd8hp3983gd"))

(define rust-gix-submodule-0.24.0
  (crate-source "gix-submodule" "0.24.0"
                "0694xhdp4c01fs0ygbbnswkphls4fd8ala00w46xh4w435hjmvpg"))

(define rust-gix-tempfile-20.0.1
  (crate-source "gix-tempfile" "20.0.1"
                "0h6xn1fcqzl7pf8xy0imag47810z573pff7dck9l43w5fj7232dd"))

(define rust-gix-trace-0.1.18
  (crate-source "gix-trace" "0.1.18"
                "1q32n7l0lpa70crx3vh356l6r8s7x11q3q25d35d8dw47dj176pn"))

(define rust-gix-transport-0.52.1
  (crate-source "gix-transport" "0.52.1"
                "13cinjmw2lbjy36c1ng16pnmi2xrl36nx28ic6i73rzbl81fvm54"))

(define rust-gix-traverse-0.51.1
  (crate-source "gix-traverse" "0.51.1"
                "102jkzilcwg5kjz6dr10cy7hldszz41aqj34mjavwi0p3lyvhlnh"))

(define rust-gix-url-0.34.0
  (crate-source "gix-url" "0.34.0"
                "1nbkzszvih031brjpidcbqssxhb985klq8l9kmlv6c4lzdnrkwfg"))

(define rust-gix-utils-0.3.1
  (crate-source "gix-utils" "0.3.1"
                "1igpdrs5dxlk5y7hx8c05pkqbv8vf540lxhzb5a2i393n7gxpz5y"))

(define rust-gix-validate-0.10.1
  (crate-source "gix-validate" "0.10.1"
                "1r7xvdhvvf0dl83x8ysf6j5cpzd8f52ysw7qjjjp1s8nnnjn67jv"))

(define rust-gix-worktree-0.46.0
  (crate-source "gix-worktree" "0.46.0"
                "1jka6b0lgdnf138sy2hy6ch8sijijcravl9mscbn3q5zrpl7ryqw"))

(define rust-glob-0.3.3
  (crate-source "glob" "0.3.3"
                "106jpd3syfzjfj2k70mwm0v436qbx96wig98m4q8x071yrq35hhc"))

(define rust-globset-0.4.18
  (crate-source "globset" "0.4.18"
                "1qsp3wg0mgxzmshcgymdlpivqlc1bihm6133pl6dx2x4af8w3psj"))

(define rust-half-2.7.1
  (crate-source "half" "2.7.1"
                "0jyq42xfa6sghc397mx84av7fayd4xfxr4jahsqv90lmjr5xi8kf"))

(define rust-hash32-0.3.1
  (crate-source "hash32" "0.3.1"
                "01h68z8qi5gl9lnr17nz10lay8wjiidyjdyd60kqx8ibj090pmj7"))

(define rust-hashbrown-0.14.5
  (crate-source "hashbrown" "0.14.5"
                "1wa1vy1xs3mp11bn3z9dv0jricgr6a2j0zkf1g19yz3vw4il89z5"))

(define rust-hashbrown-0.15.5
  (crate-source "hashbrown" "0.15.5"
                "189qaczmjxnikm9db748xyhiw04kpmhm9xj9k9hg0sgx7pjwyacj"))

(define rust-hashbrown-0.16.1
  (crate-source "hashbrown" "0.16.1"
                "004i3njw38ji3bzdp9z178ba9x3k0c1pgy8x69pj7yfppv4iq7c4"))

(define rust-hashbrown-0.17.0
  (crate-source "hashbrown" "0.17.0"
                "0l8gvcz80lvinb7x22h53cqbi2y1fm603y2jhhh9qwygvkb7sijg"))

(define rust-heapless-0.8.0
  (crate-source "heapless" "0.8.0"
                "1b9zpdjv4qkl2511s2c80fz16fx9in4m9qkhbaa8j73032v9xyqb"))

(define rust-heck-0.5.0
  (crate-source "heck" "0.5.0"
                "1sjmpsdl8czyh9ywl3qcsfsq9a307dg4ni2vnlwgnzzqhc4y0113"))

(define rust-hermit-abi-0.5.2
  (crate-source "hermit-abi" "0.5.2"
                "1744vaqkczpwncfy960j2hxrbjl1q01csm84jpd9dajbdr2yy3zw"))

(define rust-hex-0.4.3
  (crate-source "hex" "0.4.3"
                "0w1a4davm1lgzpamwnba907aysmlrnygbqmfis2mqjx5m552a93z"))

(define rust-hkdf-0.13.0
  (crate-source "hkdf" "0.13.0"
                "061halz93gjbshffck2xzrrz9rmkch95rvwn5ipqd2y6433jdaja"
                #:snippet '(delete-file-recursively "tests")))

(define rust-hmac-0.12.1
  (crate-source "hmac" "0.12.1"
                "0pmbr069sfg76z7wsssfk5ddcqd9ncp79fyz6zcm6yn115yc6jbc"
                #:snippet '(delete-file-recursively "tests")))

(define rust-hmac-0.13.0
  (crate-source "hmac" "0.13.0"
                "0gw6avmix6ah63lf70dapxhml4dlcakl9f2lnm6b0hdf6abvq0v3"
                #:snippet '(delete-file-recursively "tests")))

(define rust-hstr-3.0.4
  (crate-source "hstr" "3.0.4"
                "11vqrm84n9akxbnxinbylb2lxhz95ysiyk7sy96v7nn9qc3p19gs"))

(define rust-hybrid-array-0.4.10
  (crate-source "hybrid-array" "0.4.10"
                "055jvmp7rsb44z5aimj9zbam9y33nplyagik38m0xd36yy6cyi1r"))

(define rust-iana-time-zone-0.1.65
  (crate-source "iana-time-zone" "0.1.65"
                "0w64khw5p8s4nzwcf36bwnsmqzf61vpwk9ca1920x82bk6nwj6z3"))

(define rust-iana-time-zone-haiku-0.1.2
  (crate-source "iana-time-zone-haiku" "0.1.2"
                "17r6jmj31chn7xs9698r122mapq85mfnv98bb4pg6spm0si2f67k"))

(define rust-icu-collections-2.1.1
  (crate-source "icu_collections" "2.1.1"
                "0hsblchsdl64q21qwrs4hvc2672jrf466zivbj1bwyv606bn8ssc"))

(define rust-icu-locale-core-2.1.1
  (crate-source "icu_locale_core" "2.1.1"
                "1djvdc2f5ylmp1ymzv4gcnmq1s4hqfim9nxlcm173lsd01hpifpd"))

(define rust-icu-normalizer-2.1.1
  (crate-source "icu_normalizer" "2.1.1"
                "16dmn5596la2qm0r3vih0bzjfi0vx9a20yqjha6r1y3vnql8hv2z"))

(define rust-icu-normalizer-data-2.1.1
  (crate-source "icu_normalizer_data" "2.1.1"
                "02jnzizg6q75m41l6c13xc7nkc5q8yr1b728dcgfhpzw076wrvbs"))

(define rust-icu-properties-2.1.2
  (crate-source "icu_properties" "2.1.2"
                "1v3lbmhhi7i6jgw51ikjb1p50qh5rb67grlkdnkc63l7zq1gq2q2"))

(define rust-icu-properties-data-2.1.2
  (crate-source "icu_properties_data" "2.1.2"
                "1bvpkh939rgzrjfdb7hz47v4wijngk0snmcgrnpwc9fpz162jv31"))

(define rust-icu-provider-2.1.1
  (crate-source "icu_provider" "2.1.1"
                "0576b7dizgyhpfa74kacv86y4g1p7v5ffd6c56kf1q82rvq2r5l5"))

(define rust-id-arena-2.3.0
  (crate-source "id-arena" "2.3.0"
                "0m6rs0jcaj4mg33gkv98d71w3hridghp5c4yr928hplpkgbnfc1x"))

(define rust-ident-case-1.0.1
  (crate-source "ident_case" "1.0.1"
                "0fac21q6pwns8gh1hz3nbq15j8fi441ncl6w4vlnd1cmc55kiq5r"))

(define rust-idna-1.1.0
  (crate-source "idna" "1.1.0"
                "1pp4n7hppm480zcx411dsv9wfibai00wbpgnjj4qj0xa7kr7a21v"))

(define rust-idna-adapter-1.2.1
  (crate-source "idna_adapter" "1.2.1"
                "0i0339pxig6mv786nkqcxnwqa87v4m94b2653f6k3aj0jmhfkjis"))

(define rust-ignore-0.4.25
  (crate-source "ignore" "0.4.25"
                "0jlv2s4fxqj9fsz6y015j5vbz6i475hj80j9q3sy05d0cniq5myk"))

(define rust-image-0.25.9
  (crate-source "image" "0.25.9"
                "06lwa4ag3zcmjzivl356q0qhgxxqpkp7qwda7x0mjrkq21n6ql76"))

(define rust-image-webp-0.2.4
  (crate-source "image-webp" "0.2.4"
                "1hz814csyi9283vinzlkix6qpnd6hs3fkw7xl6z2zgm4w7rrypjj"))

(define rust-imara-diff-0.1.8
  (crate-source "imara-diff" "0.1.8"
                "1lmk5dpha2fhahrnsrgavxn1qz6ydp1w8jz8fpvlb28p89ylplqp"))

(define rust-imgref-1.12.0
  (crate-source "imgref" "1.12.0"
                "1j3iwdal9mdkmyrsms3lz4n1bxxxjxss2jvbmh662fns63fcxig7"))

(define rust-indexmap-2.14.0
  (crate-source "indexmap" "2.14.0"
                "1na9z6f0d5pkjr1lgsni470v98gv2r7c41j8w48skr089x2yjrnl"))

(define rust-inout-0.1.4
  (crate-source "inout" "0.1.4"
                "008xfl1jn9rxsq19phnhbimccf4p64880jmnpg59wqi07kk117w7"))

(define rust-insta-1.47.2
  (crate-source "insta" "1.47.2"
                "0kh9gspras3vhvx8wkygnw2wzlwjln7gwzgks8g4194kxd464jkv"))

(define rust-interpolate-name-0.2.4
  (crate-source "interpolate_name" "0.2.4"
                "0q7s5mrfkx4p56dl8q9zq71y1ysdj4shh6f28qf9gly35l21jj63"))

(define rust-is-macro-0.3.7
  (crate-source "is-macro" "0.3.7"
                "1r5hvxy697qrrp284qg1f9pyrq7i3mzn1r1qfxj24k728zja6mqx"))

(define rust-is-terminal-polyfill-1.70.2
  (crate-source "is_terminal_polyfill" "1.70.2"
                "15anlc47sbz0jfs9q8fhwf0h3vs2w4imc030shdnq54sny5i7jx6"))

(define rust-itertools-0.13.0
  (crate-source "itertools" "0.13.0"
                "11hiy3qzl643zcigknclh446qb9zlg4dpdzfkjaa9q9fqpgyfgj1"))

(define rust-itertools-0.14.0
  (crate-source "itertools" "0.14.0"
                "118j6l1vs2mx65dqhwyssbrxpawa90886m3mzafdvyip41w2q69b"))

(define rust-itoa-1.0.18
  (crate-source "itoa" "1.0.18"
                "10jnd1vpfkb8kj38rlkn2a6k02afvj3qmw054dfpzagrpl6achlg"))

(define rust-ittapi-0.4.0
  (crate-source "ittapi" "0.4.0"
                "1cb41dapbximlma0vnar144m2j2km44g8g6zmv6ra4y42kk6z6bb"))

(define rust-ittapi-sys-0.4.0
  ;; TODO REVIEW: Check bundled sources.
  (crate-source "ittapi-sys" "0.4.0"
                "1z7lgc7gwlhcvkdk6bg9sf1ww4w0b41blp90hv4a4kq6ji9kixaj"))

(define rust-jiff-0.2.23
  (crate-source "jiff" "0.2.23"
                "0nc37n7jvgrzxdkcgc2hsfdf70lfagigjalh4igjrm5njvf4cd8s"))

(define rust-jiff-static-0.2.23
  (crate-source "jiff-static" "0.2.23"
                "192ss3cnixvg79cpa76clwkhn4mmz10vnwsbf7yjw8i484s8p31a"))

(define rust-jiff-tzdb-0.1.6
  (crate-source "jiff-tzdb" "0.1.6"
                "0xihzlnnyk0xnrzpq4xcyjdcmy8xc3ychzb9ayjkh4vgha2fy069"
                #:snippet '(delete-file "concatenated-zoneinfo.dat")))

(define rust-jiff-tzdb-platform-0.1.3
  (crate-source "jiff-tzdb-platform" "0.1.3"
                "1s1ja692wyhbv7f60mc0x90h7kn1pv65xkqi2y4imarbmilmlnl7"))

(define rust-jobserver-0.1.34
  (crate-source "jobserver" "0.1.34"
                "0cwx0fllqzdycqn4d6nb277qx5qwnmjdxdl0lxkkwssx77j3vyws"))

(define rust-js-sys-0.3.95
  ;; TODO REVIEW: Check bundled sources.
  (crate-source "js-sys" "0.3.95"
                "1jhj3kgxxgwm0cpdjiz7i2qapqr7ya9qswadmr63dhwx3lnyjr19"))

(define rust-json5-1.3.1
  (crate-source "json5" "1.3.1"
                "0337psmly07ypaqr96fdj96lamfbhyw8fi6bk2715vvgpm6q8fkk"))

(define rust-jsonschema-0.42.2
  (crate-source "jsonschema" "0.42.2"
                "1cir1bbcp12jgapr78i30gzbj1475wfdff7xyh5jgjbabywrnk54"))

(define rust-kstring-2.0.2
  (crate-source "kstring" "2.0.2"
                "1lfvqlqkg2x23nglznb7ah6fk3vv3y5i759h5l2151ami98gk2sm"))

(define rust-lazy-static-1.5.0
  (crate-source "lazy_static" "1.5.0"
                "1zk6dqqni0193xg6iijh7i3i44sryglwgvx20spdvwk3r6sbrlmv"))

(define rust-leb128fmt-0.1.0
  (crate-source "leb128fmt" "0.1.0"
                "1chxm1484a0bly6anh6bd7a99sn355ymlagnwj3yajafnpldkv89"))

(define rust-lebe-0.5.3
  (crate-source "lebe" "0.5.3"
                "1f459clndzzm35nyd15vj5dlasyagfasp7hcgl6lh2b658rs6ybs"))

(define rust-libc-0.2.185
  (crate-source "libc" "0.2.185"
                "13rbdaa59l3w92q7kfcxx8zbikm99zzw54h59aqvcv5wx47jrzsj"))

(define rust-libfuzzer-sys-0.4.12
  (crate-source "libfuzzer-sys" "0.4.12"
                "13ghagfsynmqda1pkpalila6kf0llqxh3214ynzi5knqgldnhapi"
                #:snippet '(delete-file-recursively "libfuzzer")))

(define rust-libloading-0.8.9
  (crate-source "libloading" "0.8.9"
                "0mfwxwjwi2cf0plxcd685yxzavlslz7xirss3b9cbrzyk4hv1i6p"
                #:snippet '(delete-file-recursively "tests")))

(define rust-libm-0.2.16
  (crate-source "libm" "0.2.16"
                "10brh0a3qjmbzkr5mf5xqi887nhs5y9layvnki89ykz9xb1wxlmn"))

(define rust-libredox-0.1.16
  (crate-source "libredox" "0.1.16"
                "0v54zvgknag9310wcjykgv86pgq02qr3mzgkdg4r6m1k7ns3nbz0"))

(define rust-libsqlite3-sys-0.37.0
  (crate-source "libsqlite3-sys" "0.37.0"
                "1cdrrwqarq4rq873ni5645r9cqllc73l8knkkjj62z0yqk413wdi"
                #:snippet
                '(for-each delete-file
                           (append
                            (find-files "sqlcipher" "\\.(c|h)$")
                            (find-files "sqlite3" "\\.(c|h)$")))))

(define rust-linked-hash-map-0.5.6
  (crate-source "linked-hash-map" "0.5.6"
                "03vpgw7x507g524nx5i1jf5dl8k3kv0fzg8v3ip6qqwbpkqww5q7"))

(define rust-linux-raw-sys-0.12.1
  ;; TODO REVIEW: Check bundled sources.
  (crate-source "linux-raw-sys" "0.12.1"
                "0lwasljrqxjjfk9l2j8lyib1babh2qjlnhylqzl01nihw14nk9ij"))

(define rust-litemap-0.8.2
  (crate-source "litemap" "0.8.2"
                "1w7628bc7wwcxc4n4s5kw0610xk06710nh2hn5kwwk2wa91z9nlj"))

(define rust-litrs-1.0.0
  (crate-source "litrs" "1.0.0"
                "14p0kzzkavnngvybl88nvfwv031cc2qx4vaxpfwsiifm8grdglqi"))

(define rust-lock-api-0.4.14
  (crate-source "lock_api" "0.4.14"
                "0rg9mhx7vdpajfxvdjmgmlyrn20ligzqvn8ifmaz7dc79gkrjhr2"))

(define rust-log-0.4.29
  (crate-source "log" "0.4.29"
                "15q8j9c8g5zpkcw0hnd6cf2z7fxqnvsjh3rw5mv5q10r83i34l2y"))

(define rust-loom-0.7.2.2b7c402
  ;; TODO REVIEW: Define standalone package if this is a workspace.
  (origin
    (method git-fetch)
    (uri (git-reference
          (url "https://github.com/ongardie-atomix/loom")
          (commit "2b7c402034cc041b5e325384c67bb43bff93c048")))
    (file-name (git-file-name "rust-loom" "0.7.2.2b7c402"))
    (sha256 (base32 "0nkapqsmsjdxiij7gfcygagk990k1430y5hqcmwvjn6cnkm32f5a"))))

(define rust-loop9-0.1.5
  (crate-source "loop9" "0.1.5"
                "0qphc1c0cbbx43pwm6isnwzwbg6nsxjh7jah04n1sg5h4p0qgbhg"))

(define rust-lru-0.12.5
  (crate-source "lru" "0.12.5"
                "0f1a7cgqxbyhrmgaqqa11m3azwhcc36w0v5r4izgbhadl3sg8k13"))

(define rust-lru-0.16.4
  (crate-source "lru" "0.16.4"
                "0fgg35wrpfdrkv9hcabkg92g3sv4867g1rir7ay9lq1zs3ayhrkz"))

(define rust-mach2-0.6.0
  (crate-source "mach2" "0.6.0"
                "0asmmmvsvf9ipn2jszazhhlrqv8qgcglwdh0n3r470pna70hirns"))

(define rust-matchers-0.2.0
  (crate-source "matchers" "0.2.0"
                "1sasssspdj2vwcwmbq3ra18d3qniapkimfcbr47zmx6750m5llni"))

(define rust-maybe-async-0.2.10
  (crate-source "maybe-async" "0.2.10"
                "04fvg2ywb2p9dzf7i35xqfibxc05k1pirv36jswxcqg3qw82ryaw"))

(define rust-maybe-rayon-0.1.1
  (crate-source "maybe-rayon" "0.1.1"
                "06cmvhj4n36459g327ng5dnj8d58qs472pv5ahlhm7ynxl6g78cf"))

(define rust-md-5-0.10.6
  (crate-source "md-5" "0.10.6"
                "1kvq5rnpm4fzwmyv5nmnxygdhhb2369888a06gdc9pxyrzh7x7nq"
                #:snippet '(delete-file-recursively "tests")))

(define rust-memchr-2.8.0
  (crate-source "memchr" "2.8.0"
                "0y9zzxcqxvdqg6wyag7vc3h0blhdn7hkq164bxyx2vph8zs5ijpq"))

(define rust-memfd-0.6.5
  (crate-source "memfd" "0.6.5"
                "09sj2xhn592adr14mss8b433fdn8ikyq02m4dr3a0555mq9fnf5d"))

(define rust-memmap2-0.9.11
  (crate-source "memmap2" "0.9.11"
                "1h4qnzgarnn488ljjpg9ns5y4bw0sq0xv0fj0iqywagjnz8rw8fi"))

(define rust-memoffset-0.9.1
  (crate-source "memoffset" "0.9.1"
                "12i17wh9a9plx869g7j4whf62xw68k5zd4k0k5nh6ys5mszid028"))

(define rust-minimal-lexical-0.2.1
  (crate-source "minimal-lexical" "0.2.1"
                "16ppc5g84aijpri4jzv14rvcnslvlpphbszc7zzp6vfkddf4qdb8"))

(define rust-miniz-oxide-0.8.9
  (crate-source "miniz_oxide" "0.8.9"
                "05k3pdg8bjjzayq3rf0qhpirq9k37pxnasfn4arbs17phqn6m9qz"))

(define rust-mio-1.2.0
  (crate-source "mio" "1.2.0"
                "1hanrh4fwsfkdqdaqfidz48zz1wdix23zwn3r2x78am0garfbdsh"))

(define rust-moxcms-0.7.11
  (crate-source "moxcms" "0.7.11"
                "15qa5znj029i7677l0hdv0lwmjggrg920bhjgs3cjvydb72mg5dc"))

(define rust-new-debug-unreachable-1.0.6
  (crate-source "new_debug_unreachable" "1.0.6"
                "11phpf1mjxq6khk91yzcbd3ympm78m3ivl7xg6lg2c0lf66fy3k5"))

(define rust-nix-0.31.2
  (crate-source "nix" "0.31.2"
                "1lzmcqcnb9z8l4aq5ympx71bcwc0y5yf7d8jv6hnn7hc682hfvax"))

(define rust-nkeys-0.4.5
  (crate-source "nkeys" "0.4.5"
                "1gyi8g3nzcr4cizirb0cr92ldwwlzqyawdd9ypywg8a7pjx13447"))

(define rust-no-std-io2-0.9.3
  (crate-source "no_std_io2" "0.9.3"
                "0l0mcg7gb1705rj9dnlr29q500rhklyvnjjzc1ad61vf9f1df7mm"))

(define rust-nom-7.1.3
  (crate-source "nom" "7.1.3"
                "0jha9901wxam390jcf5pfa0qqfrgh8li787jx2ip0yk5b8y9hwyj"))

(define rust-nom-8.0.0
  (crate-source "nom" "8.0.0"
                "01cl5xng9d0gxf26h39m0l8lprgpa00fcc75ps1yzgbib1vn35yz"))

(define rust-noop-proc-macro-0.3.0
  (crate-source "noop_proc_macro" "0.3.0"
                "1j2v1c6ric4w9v12h34jghzmngcwmn0hll1ywly4h6lcm4rbnxh6"))

(define rust-ntapi-0.4.3
  (crate-source "ntapi" "0.4.3"
                "1bl0d73avwla7laa4pkqvzvifjbs0avg65w01zxjydgx3likbcy3"))

(define rust-nu-ansi-term-0.50.3
  (crate-source "nu-ansi-term" "0.50.3"
                "1ra088d885lbd21q1bxgpqdlk1zlndblmarn948jz2a40xsbjmvr"))

(define rust-num-0.4.3
  (crate-source "num" "0.4.3"
                "08yb2fc1psig7pkzaplm495yp7c30m4pykpkwmi5bxrgid705g9m"))

(define rust-num-bigint-0.4.6
  (crate-source "num-bigint" "0.4.6"
                "1f903zd33i6hkjpsgwhqwi2wffnvkxbn6rv4mkgcjcqi7xr4zr55"))

(define rust-num-cmp-0.1.0
  (crate-source "num-cmp" "0.1.0"
                "1alavi36shn32b3cwbmkncj1wal3y3cwzkm21bxy5yil5hp5ncv3"))

(define rust-num-complex-0.4.6
  (crate-source "num-complex" "0.4.6"
                "15cla16mnw12xzf5g041nxbjjm9m85hdgadd5dl5d0b30w9qmy3k"))

(define rust-num-conv-0.2.1
  (crate-source "num-conv" "0.2.1"
                "0rqrr29brafaa2za352pbmhkk556n7f8z9rrkgmjp1idvdl3fry6"))

(define rust-num-derive-0.4.2
  (crate-source "num-derive" "0.4.2"
                "00p2am9ma8jgd2v6xpsz621wc7wbn1yqi71g15gc3h67m7qmafgd"))

(define rust-num-integer-0.1.46
  (crate-source "num-integer" "0.1.46"
                "13w5g54a9184cqlbsq80rnxw4jj4s0d8wv75jsq5r2lms8gncsbr"))

(define rust-num-iter-0.1.45
  (crate-source "num-iter" "0.1.45"
                "1gzm7vc5g9qsjjl3bqk9rz1h6raxhygbrcpbfl04swlh0i506a8l"))

(define rust-num-rational-0.4.2
  (crate-source "num-rational" "0.4.2"
                "093qndy02817vpgcqjnj139im3jl7vkq4h68kykdqqh577d18ggq"))

(define rust-num-traits-0.2.19
  (crate-source "num-traits" "0.2.19"
                "0h984rhdkkqd4ny9cif7y2azl3xdfb7768hb9irhpsch4q3gq787"))

(define rust-num-cpus-1.17.0
  (crate-source "num_cpus" "1.17.0"
                "0fxjazlng4z8cgbmsvbzv411wrg7x3hyxdq8nxixgzjswyylppwi"))

(define rust-num-threads-0.1.7
  (crate-source "num_threads" "0.1.7"
                "1ngajbmhrgyhzrlc4d5ga9ych1vrfcvfsiqz6zv0h2dpr2wrhwsw"))

(define rust-objc2-0.6.4
  (crate-source "objc2" "0.6.4"
                "17x8qpl512frscfqbmgjr20kg3y4r0xdqxphja17dz5f0znsh4is"))

(define rust-objc2-app-kit-0.3.2
  (crate-source "objc2-app-kit" "0.3.2"
                "132ijwni8lsi8phq7wnmialkxp46zx998fns3zq5np0ya1mr77nl"))

(define rust-objc2-core-foundation-0.3.2
  (crate-source "objc2-core-foundation" "0.3.2"
                "0dnmg7606n4zifyjw4ff554xvjmi256cs8fpgpdmr91gckc0s61a"))

(define rust-objc2-core-graphics-0.3.2
  (crate-source "objc2-core-graphics" "0.3.2"
                "01x8413pxq0m5rwidlaczni8v5cz9dc3xqzq8l9zlpl9cv8cj8p0"))

(define rust-objc2-encode-4.1.0
  (crate-source "objc2-encode" "4.1.0"
                "0cqckp4cpf68mxyc2zgnazj8klv0z395nsgbafa61cjgsyyan9gg"))

(define rust-objc2-foundation-0.3.2
  (crate-source "objc2-foundation" "0.3.2"
                "0wijkxzzvw2xkzssds3fj8279cbykz2rz9agxf6qh7y2agpsvq73"))

(define rust-objc2-io-kit-0.3.2
  (crate-source "objc2-io-kit" "0.3.2"
                "05dvfcf97w39daaj5qsbfc399lw9hbx3s4h9nwgxrmlpjnizpyik"))

(define rust-objc2-io-surface-0.3.2
  (crate-source "objc2-io-surface" "0.3.2"
                "07fqx4fmwydf2arrc4xs4awv7zyzzxh60fyqdfmrpm9n148qh1qq"))

(define rust-objc2-open-directory-0.3.2
  (crate-source "objc2-open-directory" "0.3.2"
                "0vb77yig142s54vrhlcq98ykv8qm82x2n1yzzqfj1xgd4z9bx0mv"))

(define rust-object-0.37.3
  (crate-source "object" "0.37.3"
                "1zikiy9xhk6lfx1dn2gn2pxbnfpmlkn0byd7ib1n720x0cgj0xpz"))

(define rust-object-0.39.1
  (crate-source "object" "0.39.1"
                "16vkcaamik55jd9f04g73hvgsm5w636gb4w06x3nafvsih4nqnif"))

(define rust-oid-registry-0.8.1
  (crate-source "oid-registry" "0.8.1"
                "1dxm6qkkkk4dq3ln1v83d80k8bvicm6mspsxrj3n06yy7pzhrx0j"))

(define rust-once-cell-1.21.4
  (crate-source "once_cell" "1.21.4"
                "0l1v676wf71kjg2khch4dphwh1jp3291ffiymr2mvy1kxd5kwz4z"))

(define rust-once-cell-polyfill-1.70.2
  (crate-source "once_cell_polyfill" "1.70.2"
                "1zmla628f0sk3fhjdjqzgxhalr2xrfna958s632z65bjsfv8ljrq"))

(define rust-onig-6.5.1
  (crate-source "onig" "6.5.1"
                "1w63vbzamn2v9jpnlj3wkglapqss0fcvhhd8pqafzkis8iirqsrk"))

(define rust-onig-sys-69.9.1
  (crate-source "onig_sys" "69.9.1"
                "1p17cxzqnpqzpzamh7aqwpagxlnbhzs6myxw4dgz2v9xxxp6ry67"
                #:snippet '(delete-file-recursively "oniguruma")))

(define rust-oorandom-11.1.5
  (crate-source "oorandom" "11.1.5"
                "07mlf13z453fq01qff38big1lh83j8l6aaglf63ksqzzqxc0yyfn"))

(define rust-opaque-debug-0.3.1
  (crate-source "opaque-debug" "0.3.1"
                "10b3w0kydz5jf1ydyli5nv10gdfp97xh79bgz327d273bs46b3f0"))

(define rust-option-ext-0.2.0
  (crate-source "option-ext" "0.2.0"
                "0zbf7cx8ib99frnlanpyikm1bx8qn8x602sw1n7bg6p9x94lyx04"))

(define rust-os-pipe-1.2.3
  (crate-source "os_pipe" "1.2.3"
                "0rqrvm7fdp790b4ks3kcdzsgkz2528xrn3vxc9l4nf1inj2ax3vx"))

(define rust-outref-0.5.2
  (crate-source "outref" "0.5.2"
                "03pzw9aj4qskqhh0fkagy2mkgfwgj5a1m67ajlba5hw80h68100s"))

(define rust-page-size-0.6.0
  (crate-source "page_size" "0.6.0"
                "1nj0rrwpvagagssljbm29ww1iyrrg15p1q4sk70r2cfi9qcv5m9h"))

(define rust-par-core-2.0.0
  (crate-source "par-core" "2.0.0"
                "03y9yhzg90wm0dn7bqjrpldaj5xmg6kkivsibndb4zsv4lhvsv79"))

(define rust-parking-2.2.1
  (crate-source "parking" "2.2.1"
                "1fnfgmzkfpjd69v4j9x737b1k8pnn054bvzcn5dm3pkgq595d3gk"))

(define rust-parking-lot-0.12.5
  (crate-source "parking_lot" "0.12.5"
                "06jsqh9aqmc94j2rlm8gpccilqm6bskbd67zf6ypfc0f4m9p91ck"))

(define rust-parking-lot-core-0.9.12
  (crate-source "parking_lot_core" "0.9.12"
                "1hb4rggy70fwa1w9nb0svbyflzdc69h047482v2z3sx2hmcnh896"))

(define rust-paste-1.0.15
  (crate-source "paste" "1.0.15"
                "02pxffpdqkapy292harq6asfjvadgp1s005fip9ljfsn9fvxgh2p"))

(define rust-pastey-0.1.1
  (crate-source "pastey" "0.1.1"
                "1v389jkifv757903flrrps67dvc6q6giwlyx3xi33hcfjmgjxyrm"))

(define rust-pastey-0.2.3
  (crate-source "pastey" "0.2.3"
                "1d1mk45ma9w54ppws8x096q96qhqirxmj9j3hchj7fmi1087zrif"))

(define rust-pbkdf2-0.12.2
  (crate-source "pbkdf2" "0.12.2"
                "1wms79jh4flpy1zi8xdp4h8ccxv4d85adc6zjagknvppc5vnmvgq"))

(define rust-pem-rfc7468-0.7.0
  (crate-source "pem-rfc7468" "0.7.0"
                "04l4852scl4zdva31c1z6jafbak0ni5pi0j38ml108zwzjdrrcw8"
                #:snippet '(delete-file-recursively "tests")))

(define rust-percent-encoding-2.3.2
  (crate-source "percent-encoding" "2.3.2"
                "083jv1ai930azvawz2khv7w73xh8mnylk7i578cifndjn5y64kwv"))

(define rust-petgraph-0.6.5
  (crate-source "petgraph" "0.6.5"
                "1ns7mbxidnn2pqahbbjccxkrqkrll2i5rbxx43ns6rh6fn3cridl"
                #:snippet '(for-each delete-file-recursively '("assets"))))

(define rust-phf-0.11.3
  (crate-source "phf" "0.11.3"
                "0y6hxp1d48rx2434wgi5g8j1pr8s5jja29ha2b65435fh057imhz"))

(define rust-phf-generator-0.11.3
  (crate-source "phf_generator" "0.11.3"
                "0gc4np7s91ynrgw73s2i7iakhb4lzdv1gcyx7yhlc0n214a2701w"))

(define rust-phf-macros-0.11.3
  (crate-source "phf_macros" "0.11.3"
                "05kjfbyb439344rhmlzzw0f9bwk9fp95mmw56zs7yfn1552c0jpq"))

(define rust-phf-shared-0.11.3
  (crate-source "phf_shared" "0.11.3"
                "1rallyvh28jqd9i916gk5gk2igdmzlgvv5q0l3xbf3m6y8pbrsk7"))

(define rust-pin-project-1.1.11
  (crate-source "pin-project" "1.1.11"
                "05zm3y3bl83ypsr6favxvny2kys4i19jiz1y18ylrbxwsiz9qx7i"))

(define rust-pin-project-internal-1.1.11
  (crate-source "pin-project-internal" "1.1.11"
                "1ik4mpb92da75inmjvxf2qm61vrnwml3x24wddvrjlqh1z9hxcnr"))

(define rust-pin-project-lite-0.2.17
  (crate-source "pin-project-lite" "0.2.17"
                "1kfmwvs271si96zay4mm8887v5khw0c27jc9srw1a75ykvgj54x8"))

(define rust-pkcs8-0.10.2
  (crate-source "pkcs8" "0.10.2"
                "1dx7w21gvn07azszgqd3ryjhyphsrjrmq5mmz1fbxkj5g0vv4l7r"
                #:snippet '(delete-file-recursively "tests")))

(define rust-pkg-config-0.3.33
  (crate-source "pkg-config" "0.3.33"
                "17jnqmcbxsnwhg9gjf0nh6dj5k0x3hgwi3mb9krjnmfa9v435w8r"))

(define rust-plain-0.2.3
  (crate-source "plain" "0.2.3"
                "19n1xbxb4wa7w891268bzf6cbwq4qvdb86bik1z129qb0xnnnndl"))

(define rust-plist-1.10.0
  (crate-source "plist" "1.10.0"
                "11bz122270sdjaldw2pq77sc0hfj2a3zbh4s3521wpfxlrfxd8bx"))

(define rust-plotters-0.3.7
  (crate-source "plotters" "0.3.7"
                "0ixpy9svpmr2rkzkxvvdpysjjky4gw104d73n7pi2jbs7m06zsss"))

(define rust-plotters-backend-0.3.7
  (crate-source "plotters-backend" "0.3.7"
                "0ahpliim4hrrf7d4ispc2hwr7rzkn6d6nf7lyyrid2lm28yf2hnz"))

(define rust-plotters-svg-0.3.7
  (crate-source "plotters-svg" "0.3.7"
                "0w56sxaa2crpasa1zj0bhxzihlapqfkncggavyngg0w86anf5fji"))

(define rust-png-0.18.1
  (crate-source "png" "0.18.1"
                "0qca282xp8a6d7mikxrwji3f52mjn4vnqxz2v9iz5adj665rnxk0"))

(define rust-polling-3.11.0
  (crate-source "polling" "3.11.0"
                "0622qfbxi3gb0ly2c99n3xawp878fkrd1sl83hjdhisx11cly3jx"))

(define rust-poly1305-0.8.0
  (crate-source "poly1305" "0.8.0"
                "1grs77skh7d8vi61ji44i8gpzs3r9x7vay50i6cg8baxfa8bsnc1"
                #:snippet '(delete-file-recursively "src/fuzz")))

(define rust-polyval-0.6.2
  (crate-source "polyval" "0.6.2"
                "09gs56vm36ls6pyxgh06gw2875z2x77r8b2km8q28fql0q6yc7wx"))

(define rust-portable-atomic-1.13.1
  (crate-source "portable-atomic" "1.13.1"
                "0j8vlar3n5acyigq8q6f4wjx3k3s5yz0rlpqrv76j73gi5qr8fn3"))

(define rust-portable-atomic-util-0.2.7
  (crate-source "portable-atomic-util" "0.2.7"
                "0616j0fhy6y71hyxg3n86f6hng0fmsc269s3wp4gl8ww4p8hd8f2"))

(define rust-postcard-1.1.3
  (crate-source "postcard" "1.1.3"
                "094srff139n7m8g5ssq36ag6s29ikf7fgpz660x2hkj5vnsw6r37"))

(define rust-potential-utf-0.1.5
  (crate-source "potential_utf" "0.1.5"
                "0r0518fr32xbkgzqap509s3r60cr0iancsg9j1jgf37cyz7b20q1"))

(define rust-powerfmt-0.2.0
  (crate-source "powerfmt" "0.2.0"
                "14ckj2xdpkhv3h6l5sdmb9f1d57z8hbfpdldjc2vl5givq2y77j3"))

(define rust-ppv-lite86-0.2.21
  (crate-source "ppv-lite86" "0.2.21"
                "1abxx6qz5qnd43br1dd9b2savpihzjza8gb4fbzdql1gxp2f7sl5"))

(define rust-pretty-assertions-1.4.1
  (crate-source "pretty_assertions" "1.4.1"
                "0v8iq35ca4rw3rza5is3wjxwsf88303ivys07anc5yviybi31q9s"
                #:snippet '(delete-file-recursively "examples")))

(define rust-prettyplease-0.2.37
  (crate-source "prettyplease" "0.2.37"
                "0azn11i1kh0byabhsgab6kqs74zyrg69xkirzgqyhz6xmjnsi727"))

(define rust-proc-macro-crate-3.5.0
  (crate-source "proc-macro-crate" "3.5.0"
                "0kv1g1d1zjwxlgcaba2qlshzyy32j03xic8rskqlcr5mnblsfyz6"))

(define rust-proc-macro-error-attr2-2.0.0
  (crate-source "proc-macro-error-attr2" "2.0.0"
                "1ifzi763l7swl258d8ar4wbpxj4c9c2im7zy89avm6xv6vgl5pln"))

(define rust-proc-macro-error2-2.0.1
  (crate-source "proc-macro-error2" "2.0.1"
                "00lq21vgh7mvyx51nwxwf822w2fpww1x0z8z0q47p8705g2hbv0i"))

(define rust-proc-macro2-1.0.106
  (crate-source "proc-macro2" "1.0.106"
                "0d09nczyaj67x4ihqr5p7gxbkz38gxhk4asc0k8q23g9n85hzl4g"))

(define rust-prodash-30.0.1
  (crate-source "prodash" "30.0.1"
                "0fdi0wxgy3s9643dgyfkwgmm12g4a360djy56zbxkls9d1bgqvjs"))

(define rust-profiling-1.0.17
  (crate-source "profiling" "1.0.17"
                "0wqp6i1bl7azy9270dp92srbbr55mgdh9qnk5b1y44lyarmlif1y"))

(define rust-profiling-procmacros-1.0.17
  (crate-source "profiling-procmacros" "1.0.17"
                "0nrxdh5r723raxbs136jmjx46p0c5qgai8jwz4j555mn0ad7ywaj"))

(define rust-proptest-1.11.0
  (crate-source "proptest" "1.11.0"
                "0i27rr5drw4ic8hjzx6i1c6q8s7kmsgpfmzy4m80ys2c6k1gqiab"))

(define rust-prost-0.14.3
  (crate-source "prost" "0.14.3"
                "0s057z9nzggzy7x4bbsiar852hg7zb81f4z4phcdb0ig99971snj"))

(define rust-prost-derive-0.14.3
  (crate-source "prost-derive" "0.14.3"
                "02zvva6kb0pfvlyc4nac6gd37ncjrs8jq5scxcq4nbqkc8wh5ii7"))

(define rust-psm-0.1.30
  (crate-source "psm" "0.1.30"
                "1n0q1n5zx73gfl7zbc73n873lj6wz2dq3mxjy1s4sqyzcxj7cliq"
                #:snippet '(delete-file "src/arch/wasm32.o")))

(define rust-pulldown-cmark-0.13.3
  (crate-source "pulldown-cmark" "0.13.3"
                "1bgxjn869lyyb8yc7cpj0pm1127kmrhh8hfby6b3g27sdn4i8fkw"))

(define rust-pulldown-cmark-escape-0.11.0
  (crate-source "pulldown-cmark-escape" "0.11.0"
                "1bp13akkz52p43vh2ffpgv604l3xd9b67b4iykizidnsbpdqlz80"))

(define rust-pulley-interpreter-47.0.3
  (crate-source "pulley-interpreter" "47.0.3"
                "02ib9x3sgvsp9bpj1kwf1jz9sxvia727s1idvzxlwbh3x8hqqp5w"))

(define rust-pulley-macros-47.0.3
  (crate-source "pulley-macros" "47.0.3"
                "0x05k1c2nbqy3524mqcf9ij8hm5sjzksskk0wdifkpfmama9444z"))

(define rust-pxfm-0.1.29
  (crate-source "pxfm" "0.1.29"
                "0gvfd9r73i2mqf1cdc2y5yf0m0skhc16a5aglxiwsv2c57swrig0"))

(define rust-qoi-0.4.1
  (crate-source "qoi" "0.4.1"
                "00c0wkb112annn2wl72ixyd78mf56p4lxkhlmsggx65l3v3n8vbz"
                #:snippet '(delete-file-recursively "doc")))

(define rust-quick-error-1.2.3
  (crate-source "quick-error" "1.2.3"
                "1q6za3v78hsspisc197bg3g7rpc989qycy8ypr8ap8igv10ikl51"))

(define rust-quick-error-2.0.1
  (crate-source "quick-error" "2.0.1"
                "18z6r2rcjvvf8cn92xjhm2qc3jpd1ljvcbf12zv0k9p565gmb4x9"))

(define rust-quick-xml-0.41.0
  (crate-source "quick-xml" "0.41.0"
                "1h9y8zry34r3mxfd5vqfj50vvvzvri4kzbx5d657jkqjalg4aq76"))

(define rust-quote-1.0.45
  (crate-source "quote" "1.0.45"
                "095rb5rg7pbnwdp6v8w5jw93wndwyijgci1b5lw8j1h5cscn3wj1"))

(define rust-r-efi-5.3.0
  (crate-source "r-efi" "5.3.0"
                "03sbfm3g7myvzyylff6qaxk4z6fy76yv860yy66jiswc2m6b7kb9"))

(define rust-r-efi-6.0.0
  (crate-source "r-efi" "6.0.0"
                "1gyrl2k5fyzj9k7kchg2n296z5881lg7070msabid09asp3wkp7q"))

(define rust-rand-0.8.6
  (crate-source "rand" "0.8.6"
                "12kd4rljn86m00rcaz4c1rcya4mb4gk5ig6i8xq00a8wjgxfr82w"))

(define rust-rand-0.9.4
  (crate-source "rand" "0.9.4"
                "1sknbxgs6nfg0nxdd7689lwbyr2i4vaswchrv4b34z8vpc3azia4"))

(define rust-rand-chacha-0.3.1
  (crate-source "rand_chacha" "0.3.1"
                "123x2adin558xbhvqb8w4f6syjsdkmqff8cxwhmjacpsl1ihmhg6"))

(define rust-rand-chacha-0.9.0
  (crate-source "rand_chacha" "0.9.0"
                "1jr5ygix7r60pz0s1cv3ms1f6pd1i9pcdmnxzzhjc3zn3mgjn0nk"))

(define rust-rand-core-0.6.4
  (crate-source "rand_core" "0.6.4"
                "0b4j2v4cb5krak1pv6kakv4sz6xcwbrmy2zckc32hsigbrwy82zc"))

(define rust-rand-core-0.9.5
  (crate-source "rand_core" "0.9.5"
                "0g6qc5r3f0hdmz9b11nripyp9qqrzb0xqk9piip8w8qlvqkcibvn"))

(define rust-rand-xorshift-0.4.0
  (crate-source "rand_xorshift" "0.4.0"
                "0njsn25pis742gb6b89cpq7jp48v9n23a9fvks10yczwks8n4fai"))

(define rust-rapidhash-4.5.1
  (crate-source "rapidhash" "4.5.1"
                "17jqb1mrdg8vb79ma8gxa21vg21spb47szjvspl5is3c0f5fg9sx"))

(define rust-rav1e-0.8.1
  (crate-source "rav1e" "0.8.1"
                "0axk3ji3jmlr81svmsy5zvj8shmhpp8lz5nyghkq752xx1bdvdj3"))

(define rust-ravif-0.12.0
  (crate-source "ravif" "0.12.0"
                "11dj99rsrdjp12yn4xchxsb78prsg5s8x4smd08qmwgf1jcw2sgg"))

(define rust-rayon-1.12.0
  (crate-source "rayon" "1.12.0"
                "0vcj63xgnk72c30vdrak7dhl53snnaqv9x2faf1d94hzg1kb2fgv"))

(define rust-rayon-core-1.13.0
  (crate-source "rayon-core" "1.13.0"
                "14dbr0sq83a6lf1rfjq5xdpk5r6zgzvmzs5j6110vlv2007qpq92"))

(define rust-redox-syscall-0.5.18
  (crate-source "redox_syscall" "0.5.18"
                "0b9n38zsxylql36vybw18if68yc9jczxmbyzdwyhb9sifmag4azd"))

(define rust-redox-syscall-0.7.4
  (crate-source "redox_syscall" "0.7.4"
                "0fk4infcfn2hvshrwgf7r48rf9mr1zxy1a28d7xn798x7ffasl7l"))

(define rust-redox-users-0.4.6
  (crate-source "redox_users" "0.4.6"
                "0hya2cxx6hxmjfxzv9n8rjl5igpychav7zfi1f81pz6i4krry05s"))

(define rust-redox-users-0.5.2
  (crate-source "redox_users" "0.5.2"
                "1b17q7gf7w8b1vvl53bxna24xl983yn7bd00gfbii74bcg30irm4"))

(define rust-ref-cast-1.0.25
  (crate-source "ref-cast" "1.0.25"
                "0zdzc34qjva9xxgs889z5iz787g81hznk12zbk4g2xkgwq530m7k"))

(define rust-ref-cast-impl-1.0.25
  (crate-source "ref-cast-impl" "1.0.25"
                "1nkhn1fklmn342z5c4mzfzlxddv3x8yhxwwk02cj06djvh36065p"))

(define rust-referencing-0.42.2
  (crate-source "referencing" "0.42.2"
                "1pv64rimi17371snlh4hna85d6xfycbglrwxqmkvnlcl917i5m4p"))

(define rust-regalloc2-0.15.2
  (crate-source "regalloc2" "0.15.2"
                "11bzk983566d84xpm0v76jhmm2skalvlhqymypadd40mwvl14xvm"))

(define rust-regex-1.12.3
  (crate-source "regex" "1.12.3"
                "0xp2q0x7ybmpa5zlgaz00p8zswcirj9h8nry3rxxsdwi9fhm81z1"))

(define rust-regex-automata-0.4.14
  (crate-source "regex-automata" "0.4.14"
                "13xf7hhn4qmgfh784llcp2kzrvljd13lb2b1ca0mwnf15w9d87bf"))

(define rust-regex-syntax-0.8.10
  (crate-source "regex-syntax" "0.8.10"
                "02jx311ka0daxxc7v45ikzhcl3iydjbbb0mdrpc1xgg8v7c7v2fw"))

(define rust-relative-path-2.0.1
  (crate-source "relative-path" "2.0.1"
                "1c4jm6x0p88722c77xx53mb7zcs4xznp9d3whdsbmn1248qhm95w"))

(define rust-rgb-0.8.53
  (crate-source "rgb" "0.8.53"
                "1i0c55whln68zs6f5qqrkbg1mzai0p3qk1mwkwzdgr9i3dw4pcs7"))

(define rust-rich-rust-0.2.2
  (crate-source "rich_rust" "0.2.2"
                "05crs7x6z2z9fb6imlgxcrx3sj2rfl8yq72nwd1jfas3xcdmhfdp"))

(define rust-ring-0.17.14
  (crate-source "ring" "0.17.14"
                "1dw32gv19ccq4hsx3ribhpdzri1vnrlcfqb2vj41xn4l49n9ws54"))

(define rust-rmp-0.8.15
  (crate-source "rmp" "0.8.15"
                "033rwyzxyj5f7iviacvcz1y2wmlbadw1cma2anrwkckjsdrbxa2b"))

(define rust-rmp-serde-1.3.1
  (crate-source "rmp-serde" "1.3.1"
                "0md1cx5w0hwc40nb55z3c4j26b4npkmp06k8s5vvbycfikp1py3j"))

(define rust-rquickjs-0.11.0
  (crate-source "rquickjs" "0.11.0"
                "0yn708px5v56bxjb9a7cy2xa55vlhq2zg73nnknkkhw7qpbcc3f5"))

(define rust-rquickjs-core-0.11.0
  (crate-source "rquickjs-core" "0.11.0"
                "1h8hwc3kbskwcah34ikzrmsqqm4mzfd2lx8fn8x1qcjw5107igxq"))

(define rust-rquickjs-macro-0.11.0
  (crate-source "rquickjs-macro" "0.11.0"
                "101bmmzjd34pyg25sarnnvs81f20lkhi6slh0jqpfmhsyigj21ki"))

(define rust-rquickjs-sys-0.11.0
  ;; TODO REVIEW: Check bundled sources.
  (crate-source "rquickjs-sys" "0.11.0"
                "10wx5fzfka3d558kqpq94a0m37z9wywyrqd4ss10wii7xw0lcd17"))

(define rust-rustc-demangle-0.1.27
  (crate-source "rustc-demangle" "0.1.27"
                "17f0jl6lgsy8kwxdzxp3s2wmipvlpna03kkc4vkqr1gwv5lqh2xm"))

(define rust-rustc-hash-2.1.2
  (crate-source "rustc-hash" "2.1.2"
                "1gjdc5bw9982cj176jvgz9rrqf9xvr1q1ddpzywf5qhs7yzhlc4l"))

(define rust-rustc-version-0.4.1
  (crate-source "rustc_version" "0.4.1"
                "14lvdsmr5si5qbqzrajgb6vfn69k0sfygrvfvr2mps26xwi3mjyg"))

(define rust-rusticata-macros-4.1.0
  (crate-source "rusticata-macros" "4.1.0"
                "0ch67lljmgl5pfrlb90bl5kkp2x6yby1qaxnpnd0p5g9xjkc9w7s"))

(define rust-rustix-1.1.4
  (crate-source "rustix" "1.1.4"
                "14511f9yjqh0ix07xjrjpllah3325774gfwi9zpq72sip5jlbzmn"))

(define rust-rustls-0.23.40
  (crate-source "rustls" "0.23.40"
                "12qnv3ag4wrw7aj8jng74kgrilpjm2b1rfcjaac8h691frccv1pg"))

(define rust-rustls-pemfile-2.2.0
  (crate-source "rustls-pemfile" "2.2.0"
                "0l3f3mrfkgdjrava7ibwzgwc4h3dljw3pdkbsi9rkwz3zvji9qyw"
                #:snippet '(delete-file-recursively "tests")))

(define rust-rustls-pki-types-1.14.1
  (crate-source "rustls-pki-types" "1.14.1"
                "1a9pr54y0f3qr97bxpd3ahjldq0gqdld0h799xbnwdzbwxx1k9rh"))

(define rust-rustls-webpki-0.103.13
  (crate-source "rustls-webpki" "0.103.13"
                "0vkm7z9pnxz5qz66p2kmyy2pwx0g4jnsbqk5xzfhs4czcjl2ki31"))

(define rust-rustversion-1.0.22
  (crate-source "rustversion" "1.0.22"
                "0vfl70jhv72scd9rfqgr2n11m5i9l1acnk684m2w83w0zbqdx75k"))

(define rust-rusty-fork-0.3.1
  (crate-source "rusty-fork" "0.3.1"
                "1qkf9rvz2irb1wlbkrhrns8n9hnax48z1lgql5nqyr2fyagzfsyc"))

(define rust-ryu-1.0.23
  (crate-source "ryu" "1.0.23"
                "0zs70sg00l2fb9jwrf6cbkdyscjs53anrvai2hf7npyyfi5blx4p"))

(define rust-salsa20-0.10.2
  (crate-source "salsa20" "0.10.2"
                "04w211x17xzny53f83p8f7cj7k2hi8zck282q5aajwqzydd2z8lp"))

(define rust-same-file-1.0.6
  (crate-source "same-file" "1.0.6"
                "00h5j1w87dmhnvbv9l8bic3y7xxsnjmssvifw2ayvgx9mb1ivz4k"))

(define rust-scoped-tls-1.0.1
  (crate-source "scoped-tls" "1.0.1"
                "15524h04mafihcvfpgxd8f4bgc3k95aclz8grjkg9a0rxcvn9kz1"))

(define rust-scopeguard-1.2.0
  (crate-source "scopeguard" "1.2.0"
                "0jcz9sd47zlsgcnm1hdw0664krxwb5gczlif4qngj2aif8vky54l"))

(define rust-scrypt-0.11.0
  (crate-source "scrypt" "0.11.0"
                "07zxfaqpns9jn0mnxm7wj3ksqsinyfpirkav1f7kc2bchs2s65h5"))

(define rust-semver-1.0.28
  (crate-source "semver" "1.0.28"
                "1kaimrpy876bcgi8bfj0qqfxk77zm9iz2zhn1hp9hj685z854y4a"))

(define rust-seq-macro-0.3.6
  (crate-source "seq-macro" "0.3.6"
                "1k4sshn0x2i6a9g97sy5jl7ghlqgmmh3n76aj3rrjwxy1x0i3iqv"))

(define rust-serde-1.0.228
  (crate-source "serde" "1.0.228"
                "17mf4hhjxv5m90g42wmlbc61hdhlm6j9hwfkpcnd72rpgzm993ls"))

(define rust-serde-core-1.0.228
  (crate-source "serde_core" "1.0.228"
                "1bb7id2xwx8izq50098s5j2sqrrvk31jbbrjqygyan6ask3qbls1"))

(define rust-serde-derive-1.0.228
  (crate-source "serde_derive" "1.0.228"
                "0y8xm7fvmr2kjcd029g9fijpndh8csv5m20g4bd76w8qschg4h6m"))

(define rust-serde-json-1.0.149
  (crate-source "serde_json" "1.0.149"
                "11jdx4vilzrjjd1dpgy67x5lgzr0laplz30dhv75lnf5ffa07z43"))

(define rust-serde-spanned-0.6.9
  (crate-source "serde_spanned" "0.6.9"
                "18vmxq6qfrm110caszxrzibjhy2s54n1g5w1bshxq9kjmz7y0hdz"))

(define rust-serde-spanned-1.1.1
  (crate-source "serde_spanned" "1.1.1"
                "09jzk7i6wihn3d8i3wi4j4n98ghi93c3b8m8k64nxq0ijn3vaqk6"))

(define rust-sha1-0.10.6
  (crate-source "sha1" "0.10.6"
                "1fnnxlfg08xhkmwf2ahv634as30l1i3xhlhkvxflmasi5nd85gz3"
                #:snippet '(delete-file-recursively "tests")))

(define rust-sha1-0.11.0
  (crate-source "sha1" "0.11.0"
                "05025pf8d8zr2qq5xyh5m3wqls1fn7813gz1mfs7551mk724rk5a"
                #:snippet '(delete-file-recursively "tests")))

(define rust-sha1-checked-0.10.0
  (crate-source "sha1-checked" "0.10.0"
                "08s4h1drgwxzfn1mk11rn0r9i0rbjra1m0l2c0fbngij1jn9kxc9"
                #:snippet '(delete-file-recursively "tests")))

(define rust-sha2-0.10.9
  (crate-source "sha2" "0.10.9"
                "10xjj843v31ghsksd9sl9y12qfc48157j1xpb8v1ml39jy0psl57"
                #:snippet '(delete-file-recursively "tests")))

(define rust-sha2-0.11.0
  (crate-source "sha2" "0.11.0"
                "1x15x22c5yf54ac0np5bfqnq5x0hdw4wqzpi48zwn94ma0bsfss4"
                #:snippet '(delete-file-recursively "tests")))

(define rust-sharded-slab-0.1.7
  (crate-source "sharded-slab" "0.1.7"
                "1xipjr4nqsgw34k7a2cgj9zaasl2ds6jwn89886kww93d32a637l"))

(define rust-shell-words-1.1.1
  (crate-source "shell-words" "1.1.1"
                "0xzd5p53xl0ndnk63r0by52rhdrh6pd37szfxszkg73zb6ffcvyw"))

(define rust-shlex-1.3.0
  (crate-source "shlex" "1.3.0"
                "0r1y6bv26c1scpxvhg2cabimrmwgbp4p3wy6syj9n0c4s3q2znhg"))

(define rust-signal-hook-0.3.18
  (crate-source "signal-hook" "0.3.18"
                "1qnnbq4g2vixfmlv28i1whkr0hikrf1bsc4xjy2aasj2yina30fq"))

(define rust-signal-hook-0.4.4
  (crate-source "signal-hook" "0.4.4"
                "0gdm8kmi1mcd30gkxcwagxiqiasq0fhdlvrfsnybv3chln6c585j"))

(define rust-signal-hook-mio-0.2.5
  (crate-source "signal-hook-mio" "0.2.5"
                "1k20rr76ngvmzr6kskkl7dv8iyb84cbydpjbjk3mpcj0lykijnmp"))

(define rust-signal-hook-registry-1.4.8
  (crate-source "signal-hook-registry" "1.4.8"
                "06vc7pmnki6lmxar3z31gkyg9cw7py5x9g7px70gy2hil75nkny4"))

(define rust-signatory-0.27.1
  (crate-source "signatory" "0.27.1"
                "0caznqsnc1kxf74kgs3zjd9h8zjj5473yxv8c17hf52p43w07qy1"))

(define rust-signature-2.2.0
  (crate-source "signature" "2.2.0"
                "1pi9hd5vqfr3q3k49k37z06p7gs5si0in32qia4mmr1dancr6m3p"))

(define rust-simd-adler32-0.3.9
  (crate-source "simd-adler32" "0.3.9"
                "0532ysdwcvzyp2bwpk8qz0hijplcdwpssr5gy5r7qwqqy5z5qgbh"))

(define rust-simd-helpers-0.1.0
  (crate-source "simd_helpers" "0.1.0"
                "19idqicn9k4vhd04ifh2ff41wvna79zphdf2c81rlmpc7f3hz2cm"))

(define rust-similar-2.7.0
  (crate-source "similar" "2.7.0"
                "1aidids7ymfr96s70232s6962v5g9l4zwhkvcjp4c5hlb6b5vfxv"))

(define rust-siphasher-0.3.11
  (crate-source "siphasher" "0.3.11"
                "03axamhmwsrmh0psdw3gf7c0zc4fyl5yjxfifz9qfka6yhkqid9q"))

(define rust-siphasher-1.0.2
  (crate-source "siphasher" "1.0.2"
                "13k7cfbpcm8qgj9p2n8dwg9skv9s0hxk5my30j5chy1p4l78bamj"))

(define rust-slab-0.4.12
  (crate-source "slab" "0.4.12"
                "1xcwik6s6zbd3lf51kkrcicdq2j4c1fw0yjdai2apy9467i0sy8c"))

(define rust-smallvec-1.15.1
  (crate-source "smallvec" "1.15.1"
                "00xxdxxpgyq5vjnpljvkmy99xij5rxgh913ii1v16kzynnivgcb7"))

(define rust-smartstring-1.0.1
  (crate-source "smartstring" "1.0.1"
                "0agf4x0jz79r30aqibyfjm1h9hrjdh0harcqcvb2vapv7rijrdrz"))

(define rust-smawk-0.3.2
  (crate-source "smawk" "0.3.2"
                "0344z1la39incggwn6nl45k8cbw2x10mr5j0qz85cdz9np0qihxp"))

(define rust-socket2-0.6.3
  (crate-source "socket2" "0.6.3"
                "0gkjjcyn69hqhhlh5kl8byk5m0d7hyrp2aqwzbs3d33q208nwxis"))

(define rust-spki-0.7.3
  (crate-source "spki" "0.7.3"
                "17fj8k5fmx4w9mp27l970clrh5qa7r5sjdvbsln987xhb34dc7nr"
                #:snippet '(delete-file-recursively "tests")))

(define rust-sqlmodel-core-0.2.2
  (crate-source "sqlmodel-core" "0.2.2"
                "1pv7vxh2nihz9viy4plcp2zzsr9pm95akm7ijkjk39pyplgi194g"))

(define rust-sqlmodel-sqlite-0.2.2
  (crate-source "sqlmodel-sqlite" "0.2.2"
                "0spqsxcx8akcw10xcg8s5ds0wyx2ycanr8ww7dj2530vaybfy5p9"))

(define rust-stable-deref-trait-1.2.1
  (crate-source "stable_deref_trait" "1.2.1"
                "15h5h73ppqyhdhx6ywxfj88azmrpml9gl6zp3pwy2malqa6vxqkc"))

(define rust-stacker-0.1.23
  (crate-source "stacker" "0.1.23"
                "04y0f6yfvz8rky3b3rx2mssf6ij35bf7c88fs48r8l4xc0ilmmq8"))

(define rust-static-assertions-1.1.0
  (crate-source "static_assertions" "1.1.0"
                "0gsl6xmw10gvn3zs1rv99laj5ig7ylffnh71f9l34js4nr4r7sx2"))

(define rust-stdio-override-0.2.0
  (crate-source "stdio-override" "0.2.0"
                "1kihdm26d3b9wdkzl7hw8pchc1gr1l9c9qa71hkrykkva4p8myng"))

(define rust-streaming-iterator-0.1.9
  (crate-source "streaming-iterator" "0.1.9"
                "0845zdv8qb7zwqzglpqc0830i43xh3fb6vqms155wz85qfvk28ib"))

(define rust-string-enum-1.0.2
  (crate-source "string_enum" "1.0.2"
                "03h3wijj8gzvjgvd9rzimzv70jl2m621a90wk7yirgd73jas8dmf"))

(define rust-strsim-0.11.1
  (crate-source "strsim" "0.11.1"
                "0kzvqlw8hxqb7y598w1s0hxlnmi84sg5vsipp3yg5na5d1rvba3x"))

(define rust-subtle-2.6.1
  (crate-source "subtle" "2.6.1"
                "14ijxaymghbl1p0wql9cib5zlwiina7kall6w7g89csprkgbvhhk"))

(define rust-swc-allocator-4.0.1
  (crate-source "swc_allocator" "4.0.1"
                "1fs8riq8bjnfalxqwqq7pqghg8dkwhm2nj2n633sha5jr39fyzlx"))

(define rust-swc-atoms-9.0.0
  (crate-source "swc_atoms" "9.0.0"
                "12mvg2h2636hhhqsag78msl75ndi0yhpiy00451xf2nir8pbxk6l"))

(define rust-swc-common-18.0.1
  (crate-source "swc_common" "18.0.1"
                "17f6rr32vlxvraqampqhinym18w9yhm0dfwvmzd4g6sf4nc6dh51"))

(define rust-swc-config-3.1.2
  (crate-source "swc_config" "3.1.2"
                "15rzad529gc30gilzxsczy3ss8hp20c24q84f63fskbkxr90psbj"))

(define rust-swc-config-macro-1.0.1
  (crate-source "swc_config_macro" "1.0.1"
                "1cxh1m4kdngfcphd4f7g7w7bqnxk29q0rqcnligdq5yyws66whbv"))

(define rust-swc-ecma-ast-20.0.1
  (crate-source "swc_ecma_ast" "20.0.1"
                "1i0adbhqdwvqmhbdpznvz9yp921lr5ks0087hqw27al6sz828895"))

(define rust-swc-ecma-codegen-23.0.0
  (crate-source "swc_ecma_codegen" "23.0.0"
                "1bvvab7zqk06r2bv3v184zfic8cm9lgjlq8bx4swx38ihvkns4an"))

(define rust-swc-ecma-codegen-macros-2.0.2
  (crate-source "swc_ecma_codegen_macros" "2.0.2"
                "1f6v9p684nlkq2p7yvygbxagv4rar24pk0lp0db5lqm2q1idqxp2"))

(define rust-swc-ecma-hooks-0.4.0
  (crate-source "swc_ecma_hooks" "0.4.0"
                "10ari67spvlfwaiawnfmrzb3skcil84xfai67rjyyl0my3qxz6lc"))

(define rust-swc-ecma-parser-34.0.0
  (crate-source "swc_ecma_parser" "34.0.0"
                "0v73aj8ipy4bgjaa40h707qgn74b24vbpym5mc685yixjd1i69qq"))

(define rust-swc-ecma-transforms-base-37.0.0
  (crate-source "swc_ecma_transforms_base" "37.0.0"
                "007dhwrrks00gsawp3yxsm5a1cfma9qlr25x7r8j9mh9cr2jpsnw"))

(define rust-swc-ecma-transforms-react-41.0.1
  (crate-source "swc_ecma_transforms_react" "41.0.1"
                "1139d88dxibd5cq6j5gibgvwqm5xpkh6wsc003s89h99si8ia1wf"))

(define rust-swc-ecma-transforms-typescript-41.0.0
  (crate-source "swc_ecma_transforms_typescript" "41.0.0"
                "0kp0x1zar3rwp3dl4jm0ilan7klzfrnz3jv26j1n2qf3yj3iv765"))

(define rust-swc-ecma-utils-26.0.1
  (crate-source "swc_ecma_utils" "26.0.1"
                "1g8gl9jvw98fjshk2ql45ldzdb372ca7dpw0bbzwl5d35gcw2s9n"))

(define rust-swc-ecma-visit-20.0.0
  (crate-source "swc_ecma_visit" "20.0.0"
                "1hj808zawz5a5mkmi5svn3qjd0fbp3c11163764xrcvxf5ca4wg9"))

(define rust-swc-eq-ignore-macros-1.0.1
  (crate-source "swc_eq_ignore_macros" "1.0.1"
                "0cmnsh8pg2r708vi3vbg95jpgfky41mblrchw2anwcd64hsffv61"))

(define rust-swc-macros-common-1.0.1
  (crate-source "swc_macros_common" "1.0.1"
                "1bma5z6lsayznk2z721isvjdfxwbsz5idyx2s9ddqhs9lyxfzqda"))

(define rust-swc-visit-2.0.1
  (crate-source "swc_visit" "2.0.1"
                "18ijw8nvp5544vs01mxa88kp5x77mc72y5yj6ig1hv289d473yv2"))

(define rust-syn-2.0.117
  (crate-source "syn" "2.0.117"
                "16cv7c0wbn8amxc54n4w15kxlx5ypdmla8s0gxr2l7bv7s0bhrg6"))

(define rust-synstructure-0.13.2
  (crate-source "synstructure" "0.13.2"
                "1lh9lx3r3jb18f8sbj29am5hm9jymvbwh6jb1izsnnxgvgrp12kj"))

(define rust-syntect-5.3.0
  (crate-source "syntect" "5.3.0"
                "09f9j0hlsz5zmc0fkjdp64sjnyzcvp86pvxfk51p19cmbp04asv5"))

(define rust-sysinfo-0.39.6
  (crate-source "sysinfo" "0.39.6"
                "1rk12gjbharifw5m80ag4fyi4by2y7m5vlp69wfbf5c98kwis1yj"))

(define rust-target-lexicon-0.13.5
  (crate-source "target-lexicon" "0.13.5"
                "1jm6lmf9hsn7ri2d6v9gg6fy24lylhskh6pbxh71f82wdxd97dmd"))

(define rust-tempfile-3.27.0
  (crate-source "tempfile" "3.27.0"
                "1gblhnyfjsbg9wjg194n89wrzah7jy3yzgnyzhp56f3v9jd7wj9j"))

(define rust-termcolor-1.4.1
  (crate-source "termcolor" "1.4.1"
                "0mappjh3fj3p2nmrg4y7qv94rchwi9mzmgmfflr8p2awdj7lyy86"))

(define rust-textwrap-0.16.2
  (crate-source "textwrap" "0.16.2"
                "0mrhd8q0dnh5hwbwhiv89c6i41yzmhw4clwa592rrp24b9hlfdf1"))

(define rust-thiserror-1.0.69
  (crate-source "thiserror" "1.0.69"
                "0lizjay08agcr5hs9yfzzj6axs53a2rgx070a1dsi3jpkcrzbamn"))

(define rust-thiserror-2.0.18
  (crate-source "thiserror" "2.0.18"
                "1i7vcmw9900bvsmay7mww04ahahab7wmr8s925xc083rpjybb222"))

(define rust-thiserror-impl-1.0.69
  (crate-source "thiserror-impl" "1.0.69"
                "1h84fmn2nai41cxbhk6pqf46bxqq1b344v8yz089w1chzi76rvjg"))

(define rust-thiserror-impl-2.0.18
  (crate-source "thiserror-impl" "2.0.18"
                "1mf1vrbbimj1g6dvhdgzjmn6q09yflz2b92zs1j9n3k7cxzyxi7b"))

(define rust-thread-local-1.1.9
  (crate-source "thread_local" "1.1.9"
                "1191jvl8d63agnq06pcnarivf63qzgpws5xa33hgc92gjjj4c0pn"))

(define rust-tiff-0.10.3
  (crate-source "tiff" "0.10.3"
                "0vrkdk9cdk07rh7iifcxpn6m8zv3wz695mizhr8rb3gfgzg0b5mg"
                #:snippet '(delete-file-recursively "tests")))

(define rust-tikv-jemalloc-sys-0.6.1+5.3.0-1-ge13ca993e8ccb9ba9847cc330696e02839f328f7
  (crate-source "tikv-jemalloc-sys"
                "0.6.1+5.3.0-1-ge13ca993e8ccb9ba9847cc330696e02839f328f7"
                "0frahmfl05hppiy1sz9g14qb5jv2q4wr323d83xcx8l6mfrab2nd"
                #:snippet '(delete-file-recursively "jemalloc")))

(define rust-tikv-jemallocator-0.6.1
  (crate-source "tikv-jemallocator" "0.6.1"
                "0fh55m13396lii5wj69qh547fq9n2k7r3cczwrkhaklmgwrb8n83"))

(define rust-time-0.3.47
  (crate-source "time" "0.3.47"
                "0b7g9ly2iabrlgizliz6v5x23yq5d6bpp0mqz6407z1s526d8fvl"))

(define rust-time-core-0.1.8
  (crate-source "time-core" "0.1.8"
                "1jidl426mw48i7hjj4hs9vxgd9lwqq4vyalm4q8d7y4iwz7y353n"))

(define rust-time-macros-0.2.27
  (crate-source "time-macros" "0.2.27"
                "058ja265waq275wxvnfwavbz9r1hd4dgwpfn7a1a9a70l32y8w1f"))

(define rust-tinystr-0.8.3
  (crate-source "tinystr" "0.8.3"
                "0vfr8x285w6zsqhna0a9jyhylwiafb2kc8pj2qaqaahw48236cn8"))

(define rust-tinytemplate-1.2.1
  (crate-source "tinytemplate" "1.2.1"
                "1g5n77cqkdh9hy75zdb01adxn45mkh9y40wdr7l68xpz35gnnkdy"))

(define rust-tinyvec-1.11.0
  (crate-source "tinyvec" "1.11.0"
                "1wvycrghzmaysnw34kzwnf0mfx6r75045s24r214wnnjadqfcq9y"))

(define rust-tinyvec-macros-0.1.1
  (crate-source "tinyvec_macros" "0.1.1"
                "081gag86208sc3y6sdkshgw3vysm5d34p431dzw0bshz66ncng0z"))

(define rust-toml-0.8.23
  (crate-source "toml" "0.8.23"
                "0qnkrq4lm2sdhp3l6cb6f26i8zbnhqb7mhbmksd550wxdfcyn6yw"))

(define rust-toml-0.9.12+spec-1.1.0
  (crate-source "toml" "0.9.12+spec-1.1.0"
                "0qwqbrymqn88mg2yqyq3rj52z6p20448z0jxdbpjsbpwg5g894ng"))

(define rust-toml-1.1.2+spec-1.1.0
  (crate-source "toml" "1.1.2+spec-1.1.0"
                "1vpggpamqhw4852kic7465zsidczsla06wz6friqkkfbhigd3ww1"))

(define rust-toml-datetime-0.6.11
  (crate-source "toml_datetime" "0.6.11"
                "077ix2hb1dcya49hmi1avalwbixmrs75zgzb3b2i7g2gizwdmk92"))

(define rust-toml-datetime-0.7.5+spec-1.1.0
  (crate-source "toml_datetime" "0.7.5+spec-1.1.0"
                "0iqkgvgsxmszpai53dbip7sf2igic39s4dby29dbqf1h9bnwzqcj"))

(define rust-toml-datetime-1.1.1+spec-1.1.0
  (crate-source "toml_datetime" "1.1.1+spec-1.1.0"
                "1mws2mkkf46l7inn77azhm0vdwxngv9vsbhbl0ah33p2c9gzcr9i"))

(define rust-toml-edit-0.22.27
  (crate-source "toml_edit" "0.22.27"
                "16l15xm40404asih8vyjvnka9g0xs9i4hfb6ry3ph9g419k8rzj1"))

(define rust-toml-edit-0.25.11+spec-1.1.0
  (crate-source "toml_edit" "0.25.11+spec-1.1.0"
                "0awzffbkx33v9x4h19b5mfrwp3sn4ifr16y58sbk6j6l5v9c8n8b"))

(define rust-toml-parser-1.1.2+spec-1.1.0
  (crate-source "toml_parser" "1.1.2+spec-1.1.0"
                "09kmzc55a0j21whm290wlf5a8b18a0qc87a1s8sncrckc6wfkax2"))

(define rust-toml-write-0.1.2
  (crate-source "toml_write" "0.1.2"
                "008qlhqlqvljp1gpp9rn5cqs74gwvdgbvs92wnpq8y3jlz4zi6ax"))

(define rust-toml-writer-1.1.1+spec-1.1.0
  (crate-source "toml_writer" "1.1.1+spec-1.1.0"
                "1nwjhvvrxz8f4ck1qi4xcz2x9qhpci37nrknhxxf9sqk22dsyvbm"))

(define rust-tracing-0.1.44
  (crate-source "tracing" "0.1.44"
                "006ilqkg1lmfdh3xhg3z762izfwmxcvz0w7m4qx2qajbz9i1drv3"))

(define rust-tracing-attributes-0.1.31
  (crate-source "tracing-attributes" "0.1.31"
                "1np8d77shfvz0n7camx2bsf1qw0zg331lra0hxb4cdwnxjjwz43l"))

(define rust-tracing-core-0.1.36
  (crate-source "tracing-core" "0.1.36"
                "16mpbz6p8vd6j7sf925k9k8wzvm9vdfsjbynbmaxxyq6v7wwm5yv"))

(define rust-tracing-log-0.2.0
  (crate-source "tracing-log" "0.2.0"
                "1hs77z026k730ij1a9dhahzrl0s073gfa2hm5p0fbl0b80gmz1gf"))

(define rust-tracing-subscriber-0.3.23
  (crate-source "tracing-subscriber" "0.3.23"
                "06fkr0qhggvrs861d7f74pn3i3a10h5jsp4n70jj9ys5b675fzyb"))

(define rust-tree-sitter-0.26.8
  (crate-source "tree-sitter" "0.26.8"
                "0f055nmpkl9aq8pifkb4m5bglsb1cqrj5klf1lz5wb2qs2ax8yw8"))

(define rust-tree-sitter-bash-0.25.1
  (crate-source "tree-sitter-bash" "0.25.1"
                "0qihqn7nska917s2fc8q1pa0lsxjvsjxiw1x3mb1pjcw4xlwfply"))

(define rust-tree-sitter-javascript-0.25.0
  (crate-source "tree-sitter-javascript" "0.25.0"
                "1xckcrssvg8479aym090rgyjdakhqkshbrh6vw5sj9q6phm4y838"))

(define rust-tree-sitter-language-0.1.7
  (crate-source "tree-sitter-language" "0.1.7"
                "10hpwqd45v529p1q23d11k8wms7zifyda5s9yl7xa36ca3qr9680"))

(define rust-tree-sitter-python-0.25.0
  (crate-source "tree-sitter-python" "0.25.0"
                "072anxf7f3wn2jzpa1c8fnnskhwjjkd4qvzlc2zl1rsjjv9mzy3b"))

(define rust-tree-sitter-ruby-0.23.1
  (crate-source "tree-sitter-ruby" "0.23.1"
                "15cz4h1sfgf838r2pmf7vg9ahh0kwgkvvnjgbdbrrfzn9vm8815y"))

(define rust-tree-sitter-typescript-0.23.2
  (crate-source "tree-sitter-typescript" "0.23.2"
                "1zsyaxx3v1sd8gx2zkscwv6z1sq2nvccqpvd8k67ayllipnpcpvc"))

(define rust-triomphe-0.1.15
  (crate-source "triomphe" "0.1.15"
                "0fazg0zgq2zbjx50vkwg1zxr8nxc9skqj9rpsqcpak4jiymcasfx"))

(define rust-typenum-1.20.0
  (crate-source "typenum" "1.20.0"
                "1pj35y6q11d3y55gdl6g1h2dfhmybjming0jdi9bh0bpnqm11kj0"))

(define rust-ucd-trie-0.1.7
  (crate-source "ucd-trie" "0.1.7"
                "0wc9p07sqwz320848i52nvyjvpsxkx3kv5bfbmm6s35809fdk5i8"))

(define rust-unarray-0.1.4
  (crate-source "unarray" "0.1.4"
                "154smf048k84prsdgh09nkm2n0w0336v84jd4zikyn6v6jrqbspa"))

(define rust-unicase-2.9.0
  (crate-source "unicase" "2.9.0"
                "0hh1wrfd7807mfph2q67jsxqgw8hm82xg2fb8ln8cvblkwxbri6v"))

(define rust-unicode-bom-2.0.3
  (crate-source "unicode-bom" "2.0.3"
                "05s2sqyjanqrbds3fxam35f92npp5ci2wz9zg7v690r0448mvv3y"))

(define rust-unicode-general-category-1.1.0
  (crate-source "unicode-general-category" "1.1.0"
                "0zv7q4fdnlawjxd75bpxfll33sf3db09xd13sv85pblkq7fkp68b"))

(define rust-unicode-id-start-1.4.0
  (crate-source "unicode-id-start" "1.4.0"
                "01v0ig6a5dy75r9wwhnjfw1fzcj3nhcqj3q2c11dw6aykg99mdw1"
                #:snippet '(delete-file-recursively "tests")))

(define rust-unicode-ident-1.0.24
  (crate-source "unicode-ident" "1.0.24"
                "0xfs8y1g7syl2iykji8zk5hgfi5jw819f5zsrbaxmlzwsly33r76"))

(define rust-unicode-linebreak-0.1.5
  (crate-source "unicode-linebreak" "0.1.5"
                "07spj2hh3daajg335m4wdav6nfkl0f6c0q72lc37blr97hych29v"))

(define rust-unicode-normalization-0.1.25
  (crate-source "unicode-normalization" "0.1.25"
                "1s76dcrxw7vs32yhpi0p074apdc3s7lak7809f3qvclwij3zdm2z"))

(define rust-unicode-segmentation-1.13.2
  (crate-source "unicode-segmentation" "1.13.2"
                "135a26m4a0wj319gcw28j6a5aqvz00jmgwgmcs6szgxjf942facn"))

(define rust-unicode-width-0.1.14
  (crate-source "unicode-width" "0.1.14"
                "1bzn2zv0gp8xxbxbhifw778a7fc93pa6a1kj24jgg9msj07f7mkx"))

(define rust-unicode-width-0.2.2
  (crate-source "unicode-width" "0.2.2"
                "0m7jjzlcccw716dy9423xxh0clys8pfpllc5smvfxrzdf66h9b5l"))

(define rust-unicode-xid-0.2.6
  (crate-source "unicode-xid" "0.2.6"
                "0lzqaky89fq0bcrh6jj6bhlz37scfd8c7dsj5dq7y32if56c1hgb"))

(define rust-universal-hash-0.5.1
  (crate-source "universal-hash" "0.5.1"
                "1sh79x677zkncasa95wz05b36134822w6qxmi1ck05fwi33f47gw"))

(define rust-untrusted-0.9.0
  (crate-source "untrusted" "0.9.0"
                "1ha7ib98vkc538x0z60gfn0fc5whqdd85mb87dvisdcaifi6vjwf"
                #:snippet '(delete-file-recursively "mk")))

(define rust-unty-next-0.1.2
  (crate-source "unty-next" "0.1.2"
                "07i2adgkrhfhl9pxvin94hplmdzbkxxl4ikpwda51wsh101js1hn"))

(define rust-url-2.5.8
  (crate-source "url" "2.5.8"
                "1v8f7nx3hpr1qh76if0a04sj08k86amsq4h8cvpw6wvk76jahrzz"))

(define rust-utf8-iter-1.0.4
  (crate-source "utf8_iter" "1.0.4"
                "1gmna9flnj8dbyd8ba17zigrp9c4c3zclngf5lnb5yvz1ri41hdn"))

(define rust-utf8parse-0.2.2
  (crate-source "utf8parse" "0.2.2"
                "088807qwjq46azicqwbhlmzwrbkz7l4hpw43sdkdyyk524vdxaq6"))

(define rust-uuid-1.23.1
  (crate-source "uuid" "1.23.1"
                "0xlwg23rmsfl3gx98qsyzpl24pf4bs9wi3mqx5c6i319hyb4mmyx"))

(define rust-uuid-simd-0.8.0
  (crate-source "uuid-simd" "0.8.0"
                "1n0b40m988h52xj03dkcp4plrzvz56r7xha1d681jrjg5ci85c13"))

(define rust-v-frame-0.3.9
  (crate-source "v_frame" "0.3.9"
                "1qkvb4ks33zck931vzqckjn36hkngj6l2cwmvfsnlpc7r0kpfsv6"))

(define rust-valuable-0.1.1
  (crate-source "valuable" "0.1.1"
                "0r9srp55v7g27s5bg7a2m095fzckrcdca5maih6dy9bay6fflwxs"))

(define rust-vcpkg-0.2.15
  (crate-source "vcpkg" "0.2.15"
                "09i4nf5y8lig6xgj3f7fyrvzd3nlaw4znrihw8psidvv5yk4xkdc"
                #:snippet '(delete-file-recursively "test-data")))

(define rust-vergen-9.1.0
  (crate-source "vergen" "9.1.0"
                "0xdgrs146p81vbhg5y8svch3cghyi3yf07p8c7i8v7k3v3va2jdq"))

(define rust-vergen-gix-9.1.0
  (crate-source "vergen-gix" "9.1.0"
                "1w24nrcfzc11cvsab7gmcskflbc5mpxfs1qrykwcd13bpq93jhr4"))

(define rust-vergen-lib-9.1.0
  (crate-source "vergen-lib" "9.1.0"
                "0sd5b5d5ygwi86k1b4n9vipqmyxqn4pr7qcs48pycncwgsx2jjmk"))

(define rust-version-check-0.9.5
  (crate-source "version_check" "0.9.5"
                "0nhhi4i5x89gm911azqbn7avs9mdacw2i3vcz3cnmz3mv4rqz4hb"))

(define rust-virtue-next-0.1.3
  (crate-source "virtue-next" "0.1.3"
                "1sskzkcvq4af3xjxzpmg0pmkv8fcbnd2hr0dvb1a2v0af6lhhlld"))

(define rust-visibility-0.1.1
  (crate-source "visibility" "0.1.1"
                "14dx30i16lsy09k30cl0lvjaw243lp4x3y722gldghd8nhsx2x6n"))

(define rust-vsimd-0.8.0
  (crate-source "vsimd" "0.8.0"
                "0r4wn54jxb12r0x023r5yxcrqk785akmbddqkcafz9fm03584c2w"))

(define rust-wait-timeout-0.2.1
  (crate-source "wait-timeout" "0.2.1"
                "04azqv9mnfxgvnc8j2wp362xraybakh2dy1nj22gj51rdl93pb09"))

(define rust-walkdir-2.5.0
  (crate-source "walkdir" "2.5.0"
                "0jsy7a710qv8gld5957ybrnc07gavppp963gs32xk4ag8130jy99"
                #:snippet '(for-each delete-file-recursively '("compare" "src/tests"))))

(define rust-wasi-0.11.1+wasi-snapshot-preview1
  (crate-source "wasi" "0.11.1+wasi-snapshot-preview1"
                "0jx49r7nbkbhyfrfyhz0bm4817yrnxgd3jiwwwfv0zl439jyrwyc"))

(define rust-wasip2-1.0.1+wasi-0.2.4
  (crate-source "wasip2" "1.0.1+wasi-0.2.4"
                "1rsqmpspwy0zja82xx7kbkbg9fv34a4a2if3sbd76dy64a244qh5"))

(define rust-wasip3-0.4.0+wasi-0.3.0-rc-2026-01-06
  (crate-source "wasip3" "0.4.0+wasi-0.3.0-rc-2026-01-06"
                "19dc8p0y2mfrvgk3qw3c3240nfbylv22mvyxz84dqpgai2zzha2l"))

(define rust-wasm-bindgen-0.2.118
  (crate-source "wasm-bindgen" "0.2.118"
                "129s5r14fx4v4xrzpx2c6l860nkxpl48j50y7kl6j16bpah3iy8b"))

(define rust-wasm-bindgen-futures-0.4.68
  (crate-source "wasm-bindgen-futures" "0.4.68"
                "1y7bq5d9fk7s9xaayx38bgs9ns35na0kpb5zw19944zvya1x6wgk"))

(define rust-wasm-bindgen-macro-0.2.118
  (crate-source "wasm-bindgen-macro" "0.2.118"
                "1v98r8vs17cj8918qsg0xx4nlg4nxk1g0jd4nwnyrh1687w29zzf"))

(define rust-wasm-bindgen-macro-support-0.2.118
  (crate-source "wasm-bindgen-macro-support" "0.2.118"
                "0169jr0q469hfx5zqxfyywf2h2f4aj17vn4zly02nfwqmxghc24x"))

(define rust-wasm-bindgen-shared-0.2.118
  (crate-source "wasm-bindgen-shared" "0.2.118"
                "0ag1vvdzi4334jlzilsy14y3nyzwddf1ndn62fyhf6bg62g4vl2z"))

(define rust-wasm-compose-0.252.0
  (crate-source "wasm-compose" "0.252.0"
                "06z3hi73z796mx7igkk0f5mjdcmzmkgir1b359rm8pd3a43p36ym"
                ;; tests/compositions carries a prebuilt WebAssembly fixture.
                #:snippet '(delete-file-recursively "tests")))

(define rust-wasm-encoder-0.244.0
  (crate-source "wasm-encoder" "0.244.0"
                "06c35kv4h42vk3k51xjz1x6hn3mqwfswycmr6ziky033zvr6a04r"))

(define rust-wasm-encoder-0.252.0
  (crate-source "wasm-encoder" "0.252.0"
                "0vqrsg2b83l2r4flv46r8firg5q8wx89mzr68q2pqs55bwsax1c1"))

(define rust-wasm-encoder-0.255.0
  (crate-source "wasm-encoder" "0.255.0"
                "0hhsjwfcami7iv9m175clmxxs6wn7145gl1f23n2xxjxzf1l4llv"))

(define rust-wasm-metadata-0.244.0
  (crate-source "wasm-metadata" "0.244.0"
                "02f9dhlnryd2l7zf03whlxai5sv26x4spfibjdvc3g9gd8z3a3mv"))

(define rust-wasmparser-0.244.0
  (crate-source "wasmparser" "0.244.0"
                "1zi821hrlsxfhn39nqpmgzc0wk7ax3dv6vrs5cw6kb0v5v3hgf27"))

(define rust-wasmparser-0.252.0
  (crate-source "wasmparser" "0.252.0"
                "0z32qvhy9lp4hwj154sc9gjd9vr8f4rklppmxvlmppnwrafhksyk"))

(define rust-wasmparser-0.255.0
  (crate-source "wasmparser" "0.255.0"
                "02rjqckk8f43j8crr1mzrfl5bbbw84j6kb6kj4xyfijx9gpjkqz8"))

(define rust-wasmprinter-0.252.0
  (crate-source "wasmprinter" "0.252.0"
                "0jw2hnkngdnnifmsh8y4ljfl0pd7zmahzh0mpy6sndcvw9ypjhki"))

(define rust-wasmtime-47.0.3
  (crate-source "wasmtime" "47.0.3"
                "0v2qr2c61yybi4yaph64hfskwqmn7k6g5mwidn40ck8diq4sc368"))

(define rust-wasmtime-environ-47.0.3
  (crate-source "wasmtime-environ" "47.0.3"
                "00d7zsr70j5n7671iza9gn6c7vx2jy74d6sc3dn6zir9dl9rskqk"))

(define rust-wasmtime-internal-cache-47.0.3
  (crate-source "wasmtime-internal-cache" "47.0.3"
                "0w90n1yv8il1cjqjb5n2dw0hagdrs0wzbnq784xildy5pyqjxnv5"))

(define rust-wasmtime-internal-component-macro-47.0.3
  (crate-source "wasmtime-internal-component-macro" "47.0.3"
                "075yzrp1xph07i9b1c7pk45by4r5x9a6d73zsn0lghrzxlgvkxrb"))

(define rust-wasmtime-internal-component-util-47.0.3
  (crate-source "wasmtime-internal-component-util" "47.0.3"
                "1q80jhkh4dn7il5wxjklry2311n7fjz6z04z500awp48960ng2pw"))

(define rust-wasmtime-internal-core-47.0.3
  (crate-source "wasmtime-internal-core" "47.0.3"
                "08b3g4pnkd02fnjpqd7hj10j2way1yqhsvcb4xgaqw6hp729404a"))

(define rust-wasmtime-internal-cranelift-47.0.3
  (crate-source "wasmtime-internal-cranelift" "47.0.3"
                "12y9hm6jf1bv4i2wkkjwycwgxgc0sc2jaaqxhbcj7arww34ynlb8"))

(define rust-wasmtime-internal-fiber-47.0.3
  (crate-source "wasmtime-internal-fiber" "47.0.3"
                "14b93h4a5p47w9miar1sad0ah4787xas7fvhv8wc9m30bxnxl9lv"))

(define rust-wasmtime-internal-jit-debug-47.0.3
  (crate-source "wasmtime-internal-jit-debug" "47.0.3"
                "0j9iqav79vi4lh29av43pb6ybhi7pfmljivvvmz8pxvvbni1nqpd"))

(define rust-wasmtime-internal-jit-icache-coherence-47.0.3
  (crate-source "wasmtime-internal-jit-icache-coherence" "47.0.3"
                "11cf0mcr4zxz4zpfnakw0vlb0bqfb4y6ys95lw3avfji14bbm12n"))

(define rust-wasmtime-internal-unwinder-47.0.3
  (crate-source "wasmtime-internal-unwinder" "47.0.3"
                "0kyrbn0lry5gwkyadfd23pfjvmd9751zn4backq8zymz4zaylbhi"))

(define rust-wasmtime-internal-versioned-export-macros-47.0.3
  (crate-source "wasmtime-internal-versioned-export-macros" "47.0.3"
                "1jhfz0g0hpx575g4f5jk6pmj1gfp3gx06qk9qq9zq96qpvh94d8m"))

(define rust-wasmtime-internal-wit-bindgen-47.0.3
  (crate-source "wasmtime-internal-wit-bindgen" "47.0.3"
                "1gl8w212cgh2w2k2w9jv76f2hpm1iv8qfdm4xjznmx70h5pasmn4"))

(define rust-wast-255.0.0
  (crate-source "wast" "255.0.0"
                "11p61wgiy7n49d8xijiksp5570qhvl9jqi5cagax76qr1x9yrzsm"))

(define rust-wat-1.255.0
  (crate-source "wat" "1.255.0"
                "1cg55yzamnrl1lp4hf9vpixg7zw09ma5wim08bnpwv28w612ra6x"))

(define rust-web-sys-0.3.95
  ;; TODO REVIEW: Check bundled sources.
  (crate-source "web-sys" "0.3.95"
                "0zfr2jy5bpkkggl88i43yy37p538hg20i56kwn421yj9g6qznbag"))

(define rust-webpki-roots-1.0.7
  (crate-source "webpki-roots" "1.0.7"
                "17gblaqmp51znxd2c18c04k8yfnf7s77c04n6hdmzxbcr52fxxaj"
                #:snippet '(delete-file-recursively "tests")))

(define rust-weezl-0.1.12
  (crate-source "weezl" "0.1.12"
                "122a1dhha6cib5az4ihcqlh60ns2bi6rskdv875p94lbvj6wk2m2"))

(define rust-winapi-0.3.9
  (crate-source "winapi" "0.3.9"
                "06gl025x418lchw1wxj64ycr7gha83m44cjr5sarhynd9xkrm0sw"))

(define rust-winapi-i686-pc-windows-gnu-0.4.0
  (crate-source "winapi-i686-pc-windows-gnu" "0.4.0"
                "1dmpa6mvcvzz16zg6d5vrfy4bxgg541wxrcip7cnshi06v38ffxc"
                #:snippet '(delete-file-recursively "lib")))

(define rust-winapi-util-0.1.11
  (crate-source "winapi-util" "0.1.11"
                "08hdl7mkll7pz8whg869h58c1r9y7in0w0pk8fm24qc77k0b39y2"))

(define rust-winapi-x86-64-pc-windows-gnu-0.4.0
  (crate-source "winapi-x86_64-pc-windows-gnu" "0.4.0"
                "0gqq64czqb64kskjryj8isp62m2sgvx25yyj3kpc2myh85w24bki"
                #:snippet '(delete-file-recursively "lib")))

(define rust-windows-0.62.2
  (crate-source "windows" "0.62.2"
                "10457l9ihrbw8j79z2v4plyjxkf6xvb5npd0lqwmkh702gpaszsj"))

(define rust-windows-collections-0.3.2
  (crate-source "windows-collections" "0.3.2"
                "0436rjbkqn3j9m2v2lcmwwk0l3n2r57yvqb7fcy4m8d8y5ddkci3"))

(define rust-windows-core-0.62.2
  (crate-source "windows-core" "0.62.2"
                "1swxpv1a8qvn3bkxv8cn663238h2jccq35ff3nsj61jdsca3ms5q"))

(define rust-windows-future-0.3.2
  (crate-source "windows-future" "0.3.2"
                "1jq5qs2dwzf6rl60f8gr49z2mifxsrdh4y4yfdws467ya41gkmp1"))

(define rust-windows-implement-0.60.2
  (crate-source "windows-implement" "0.60.2"
                "1psxhmklzcf3wjs4b8qb42qb6znvc142cb5pa74rsyxm1822wgh5"))

(define rust-windows-interface-0.59.3
  (crate-source "windows-interface" "0.59.3"
                "0n73cwrn4247d0axrk7gjp08p34x1723483jxjxjdfkh4m56qc9z"))

(define rust-windows-link-0.2.1
  (crate-source "windows-link" "0.2.1"
                "1rag186yfr3xx7piv5rg8b6im2dwcf8zldiflvb22xbzwli5507h"))

(define rust-windows-numerics-0.3.1
  (crate-source "windows-numerics" "0.3.1"
                "09hgbg8pf89r4090yyhh9q29ppi7yyxkgmga9ascshy19a240bkf"))

(define rust-windows-result-0.4.1
  (crate-source "windows-result" "0.4.1"
                "1d9yhmrmmfqh56zlj751s5wfm9a2aa7az9rd7nn5027nxa4zm0bp"))

(define rust-windows-strings-0.5.1
  (crate-source "windows-strings" "0.5.1"
                "14bhng9jqv4fyl7lqjz3az7vzh8pw0w4am49fsqgcz67d67x0dvq"))

(define rust-windows-sys-0.42.0
  ;; TODO REVIEW: Check bundled sources.
  (crate-source "windows-sys" "0.42.0"
                "19waf8aryvyq9pzk0gamgfwjycgzk4gnrazpfvv171cby0h1hgjs"))

(define rust-windows-sys-0.52.0
  ;; TODO REVIEW: Check bundled sources.
  (crate-source "windows-sys" "0.52.0"
                "0gd3v4ji88490zgb6b5mq5zgbvwv7zx1ibn8v3x83rwcdbryaar8"))

(define rust-windows-sys-0.59.0
  ;; TODO REVIEW: Check bundled sources.
  (crate-source "windows-sys" "0.59.0"
                "0fw5672ziw8b3zpmnbp9pdv1famk74f1l9fcbc3zsrzdg56vqf0y"))

(define rust-windows-sys-0.60.2
  ;; TODO REVIEW: Check bundled sources.
  (crate-source "windows-sys" "0.60.2"
                "1jrbc615ihqnhjhxplr2kw7rasrskv9wj3lr80hgfd42sbj01xgj"))

(define rust-windows-sys-0.61.2
  ;; TODO REVIEW: Check bundled sources.
  (crate-source "windows-sys" "0.61.2"
                "1z7k3y9b6b5h52kid57lvmvm05362zv1v8w0gc7xyv5xphlp44xf"))

(define rust-windows-targets-0.52.6
  (crate-source "windows-targets" "0.52.6"
                "0wwrx625nwlfp7k93r2rra568gad1mwd888h1jwnl0vfg5r4ywlv"))

(define rust-windows-targets-0.53.5
  (crate-source "windows-targets" "0.53.5"
                "1wv9j2gv3l6wj3gkw5j1kr6ymb5q6dfc42yvydjhv3mqa7szjia9"))

(define rust-windows-threading-0.2.1
  (crate-source "windows-threading" "0.2.1"
                "0dsvsy33vxs0153z4n39sqkzx382cjjkrd46rb3z3zfak5dvsj9r"))

(define rust-windows-aarch64-gnullvm-0.42.2
  (crate-source "windows_aarch64_gnullvm" "0.42.2"
                "1y4q0qmvl0lvp7syxvfykafvmwal5hrjb4fmv04bqs0bawc52yjr"
                #:snippet '(delete-file-recursively "lib")))

(define rust-windows-aarch64-gnullvm-0.52.6
  (crate-source "windows_aarch64_gnullvm" "0.52.6"
                "1lrcq38cr2arvmz19v32qaggvj8bh1640mdm9c2fr877h0hn591j"
                #:snippet '(delete-file-recursively "lib")))

(define rust-windows-aarch64-gnullvm-0.53.1
  (crate-source "windows_aarch64_gnullvm" "0.53.1"
                "0lqvdm510mka9w26vmga7hbkmrw9glzc90l4gya5qbxlm1pl3n59"
                #:snippet '(delete-file-recursively "lib")))

(define rust-windows-aarch64-msvc-0.42.2
  (crate-source "windows_aarch64_msvc" "0.42.2"
                "0hsdikjl5sa1fva5qskpwlxzpc5q9l909fpl1w6yy1hglrj8i3p0"
                #:snippet '(delete-file-recursively "lib")))

(define rust-windows-aarch64-msvc-0.52.6
  (crate-source "windows_aarch64_msvc" "0.52.6"
                "0sfl0nysnz32yyfh773hpi49b1q700ah6y7sacmjbqjjn5xjmv09"
                #:snippet '(delete-file-recursively "lib")))

(define rust-windows-aarch64-msvc-0.53.1
  (crate-source "windows_aarch64_msvc" "0.53.1"
                "01jh2adlwx043rji888b22whx4bm8alrk3khjpik5xn20kl85mxr"
                #:snippet '(delete-file-recursively "lib")))

(define rust-windows-i686-gnu-0.42.2
  (crate-source "windows_i686_gnu" "0.42.2"
                "0kx866dfrby88lqs9v1vgmrkk1z6af9lhaghh5maj7d4imyr47f6"
                #:snippet '(delete-file-recursively "lib")))

(define rust-windows-i686-gnu-0.52.6
  (crate-source "windows_i686_gnu" "0.52.6"
                "02zspglbykh1jh9pi7gn8g1f97jh1rrccni9ivmrfbl0mgamm6wf"
                #:snippet '(delete-file-recursively "lib")))

(define rust-windows-i686-gnu-0.53.1
  (crate-source "windows_i686_gnu" "0.53.1"
                "18wkcm82ldyg4figcsidzwbg1pqd49jpm98crfz0j7nqd6h6s3ln"
                #:snippet '(delete-file-recursively "lib")))

(define rust-windows-i686-gnullvm-0.52.6
  (crate-source "windows_i686_gnullvm" "0.52.6"
                "0rpdx1537mw6slcpqa0rm3qixmsb79nbhqy5fsm3q2q9ik9m5vhf"
                #:snippet '(delete-file-recursively "lib")))

(define rust-windows-i686-gnullvm-0.53.1
  (crate-source "windows_i686_gnullvm" "0.53.1"
                "030qaxqc4salz6l4immfb6sykc6gmhyir9wzn2w8mxj8038mjwzs"
                #:snippet '(delete-file-recursively "lib")))

(define rust-windows-i686-msvc-0.42.2
  (crate-source "windows_i686_msvc" "0.42.2"
                "0q0h9m2aq1pygc199pa5jgc952qhcnf0zn688454i7v4xjv41n24"
                #:snippet '(delete-file-recursively "lib")))

(define rust-windows-i686-msvc-0.52.6
  (crate-source "windows_i686_msvc" "0.52.6"
                "0rkcqmp4zzmfvrrrx01260q3xkpzi6fzi2x2pgdcdry50ny4h294"
                #:snippet '(delete-file-recursively "lib")))

(define rust-windows-i686-msvc-0.53.1
  (crate-source "windows_i686_msvc" "0.53.1"
                "1hi6scw3mn2pbdl30ji5i4y8vvspb9b66l98kkz350pig58wfyhy"
                #:snippet '(delete-file-recursively "lib")))

(define rust-windows-x86-64-gnu-0.42.2
  (crate-source "windows_x86_64_gnu" "0.42.2"
                "0dnbf2xnp3xrvy8v9mgs3var4zq9v9yh9kv79035rdgyp2w15scd"
                #:snippet '(delete-file-recursively "lib")))

(define rust-windows-x86-64-gnu-0.52.6
  (crate-source "windows_x86_64_gnu" "0.52.6"
                "0y0sifqcb56a56mvn7xjgs8g43p33mfqkd8wj1yhrgxzma05qyhl"
                #:snippet '(delete-file-recursively "lib")))

(define rust-windows-x86-64-gnu-0.53.1
  (crate-source "windows_x86_64_gnu" "0.53.1"
                "16d4yiysmfdlsrghndr97y57gh3kljkwhfdbcs05m1jasz6l4f4w"
                #:snippet '(delete-file-recursively "lib")))

(define rust-windows-x86-64-gnullvm-0.42.2
  (crate-source "windows_x86_64_gnullvm" "0.42.2"
                "18wl9r8qbsl475j39zvawlidp1bsbinliwfymr43fibdld31pm16"
                #:snippet '(delete-file-recursively "lib")))

(define rust-windows-x86-64-gnullvm-0.52.6
  (crate-source "windows_x86_64_gnullvm" "0.52.6"
                "03gda7zjx1qh8k9nnlgb7m3w3s1xkysg55hkd1wjch8pqhyv5m94"
                #:snippet '(delete-file-recursively "lib")))

(define rust-windows-x86-64-gnullvm-0.53.1
  (crate-source "windows_x86_64_gnullvm" "0.53.1"
                "1qbspgv4g3q0vygkg8rnql5c6z3caqv38japiynyivh75ng1gyhg"
                #:snippet '(delete-file-recursively "lib")))

(define rust-windows-x86-64-msvc-0.42.2
  (crate-source "windows_x86_64_msvc" "0.42.2"
                "1w5r0q0yzx827d10dpjza2ww0j8iajqhmb54s735hhaj66imvv4s"
                #:snippet '(delete-file-recursively "lib")))

(define rust-windows-x86-64-msvc-0.52.6
  (crate-source "windows_x86_64_msvc" "0.52.6"
                "1v7rb5cibyzx8vak29pdrk8nx9hycsjs4w0jgms08qk49jl6v7sq"
                #:snippet '(delete-file-recursively "lib")))

(define rust-windows-x86-64-msvc-0.53.1
  (crate-source "windows_x86_64_msvc" "0.53.1"
                "0l6npq76vlq4ksn4bwsncpr8508mk0gmznm6wnhjg95d19gzzfyn"
                #:snippet '(delete-file-recursively "lib")))

(define rust-winnow-0.7.15
  (crate-source "winnow" "0.7.15"
                "0i9rkl2rqpbnnxlgs20gmkj3nd0b2k8q55mjmpc2ybb84xwxjyfz"))

(define rust-winnow-1.0.2
  (crate-source "winnow" "1.0.2"
                "1l7xnfvlgy4da6gq5ip2bgcm8i9d0rwzaxg1p88nlw8lxy5p1q9f"))

(define rust-wit-bindgen-0.46.0
  (crate-source "wit-bindgen" "0.46.0"
                "0ngysw50gp2wrrfxbwgp6dhw1g6sckknsn3wm7l00vaf7n48aypi"
                #:snippet '(for-each delete-file (find-files "." "\\.(a|o|wasm)$"))))

(define rust-wit-bindgen-0.51.0
  (crate-source "wit-bindgen" "0.51.0"
                "19fazgch8sq5cvjv3ynhhfh5d5x08jq2pkw8jfb05vbcyqcr496p"
                #:snippet '(for-each delete-file (find-files "." "\\.(a|o|wasm)$"))))

(define rust-wit-bindgen-core-0.51.0
  (crate-source "wit-bindgen-core" "0.51.0"
                "1p2jszqsqbx8k7y8nwvxg65wqzxjm048ba5phaq8r9iy9ildwqga"))

(define rust-wit-bindgen-rust-0.51.0
  (crate-source "wit-bindgen-rust" "0.51.0"
                "08bzn5fsvkb9x9wyvyx98qglknj2075xk1n7c5jxv15jykh6didp"))

(define rust-wit-bindgen-rust-macro-0.51.0
  (crate-source "wit-bindgen-rust-macro" "0.51.0"
                "0ymizapzv2id89igxsz2n587y2hlfypf6n8kyp68x976fzyrn3qc"))

(define rust-wit-component-0.244.0
  (crate-source "wit-component" "0.244.0"
                "1clwxgsgdns3zj2fqnrjcp8y5gazwfa1k0sy5cbk0fsmx4hflrlx"
                #:snippet '(delete-file "libdl.so")))

(define rust-wit-parser-0.244.0
  (crate-source "wit-parser" "0.244.0"
                "0dm7avvdxryxd5b02l0g5h6933z1cw5z0d4wynvq2cywq55srj7c"
                #:snippet '(delete-file-recursively "tests")))

(define rust-wit-parser-0.252.0
  (crate-source "wit-parser" "0.252.0"
                "0b8npigdl2shbpxpqp3fap26n13n6q1ca09jrw66471p22hvwrj2"
                ;; Same treatment guix gives wit-parser 0.244.0: the test tree
                ;; carries a prebuilt WebAssembly fixture.
                #:snippet '(delete-file-recursively "tests")))

(define rust-writeable-0.6.3
  (crate-source "writeable" "0.6.3"
                "1i54d13h9bpap2hf13xcry1s4lxh7ap3923g8f3c0grd7c9fbyhz"))

(define rust-x11rb-0.13.2
  (crate-source "x11rb" "0.13.2"
                "053lvnaw9ycbl791mgwly2hw27q6vqgzrb1y5kz1as52wmdsm4wr"))

(define rust-x11rb-protocol-0.13.2
  (crate-source "x11rb-protocol" "0.13.2"
                "1g81cznbyn522b0fbis0i44wh3adad2vhsz5pzf99waf3sbc4vza"))

(define rust-x509-parser-0.18.1
  (crate-source "x509-parser" "0.18.1"
                "00jj31m702vxas7xs0vjn2863y7k4kp266w5q1ms0z85rrqhyfyl"
                #:snippet '(delete-file-recursively "assets")))

(define rust-xattr-1.6.1
  (crate-source "xattr" "1.6.1"
                "0ml1mb43gqasawillql6b344m0zgq8mz0isi11wj8vbg43a5mr1j"))

(define rust-xxhash-rust-0.8.15
  (crate-source "xxhash-rust" "0.8.15"
                "1lrmffpn45d967afw7f1p300rsx7ill66irrskxpcm1p41a0rlpx"))

(define rust-y4m-0.8.0
  (crate-source "y4m" "0.8.0"
                "0j24y2zf60lpxwd7kyg737hqfyqx16y32s0fjyi6fax6w4hlnnks"
                #:snippet '(delete-file-recursively "scripts")))

(define rust-yaml-rust-0.4.5
  (crate-source "yaml-rust" "0.4.5"
                "118wbqrr4n6wgk5rjjnlrdlahawlxc1bdsx146mwk8f79in97han"))

(define rust-yansi-1.0.1
  (crate-source "yansi" "1.0.1"
                "0jdh55jyv0dpd38ij4qh60zglbw9aa8wafqai6m0wa7xaxk3mrfg"
                #:snippet '(delete-file-recursively ".github")))

(define rust-yoke-0.8.2
  (crate-source "yoke" "0.8.2"
                "1jprcs7a98a5whvfs6r3jvfh1nnfp6zyijl7y4ywmn88lzywbs5b"))

(define rust-yoke-derive-0.8.2
  (crate-source "yoke-derive" "0.8.2"
                "13l5y5sz4lqm7rmyakjbh6vwgikxiql51xfff9hq2j485hk4r16y"))

(define rust-zerocopy-0.8.48
  (crate-source "zerocopy" "0.8.48"
                "1sb8plax8jbrsng1jdval7bdhk7hhrx40dz3hwh074k6knzkgm7f"))

(define rust-zerocopy-derive-0.8.48
  (crate-source "zerocopy-derive" "0.8.48"
                "1m5s0g92cxggqc74j83k1priz24k3z93sj5gadppd20p9c4cvqvh"))

(define rust-zerofrom-0.1.7
  (crate-source "zerofrom" "0.1.7"
                "1py40in4rirc9q8w36q67pld0zk8ssg024xhh0cncxgal7ra3yk9"))

(define rust-zerofrom-derive-0.1.7
  (crate-source "zerofrom-derive" "0.1.7"
                "18c4wsnznhdxx6m80piil1lbyszdiwsshgjrybqcm4b6qic22lqi"))

(define rust-zeroize-1.8.2
  (crate-source "zeroize" "1.8.2"
                "1l48zxgcv34d7kjskr610zqsm6j2b4fcr2vfh9jm9j1jgvk58wdr"))

(define rust-zeroize-derive-1.4.3
  (crate-source "zeroize_derive" "1.4.3"
                "0bl5vd1lz27p4z336nximg5wrlw5j7jc8fxh7iv6r1wrhhav99c5"))

(define rust-zerotrie-0.2.4
  (crate-source "zerotrie" "0.2.4"
                "1gr0pkcn3qsr6in6iixqyp0vbzwf2j1jzyvh7yl2yydh3p9m548g"))

(define rust-zerovec-0.11.6
  (crate-source "zerovec" "0.11.6"
                "0fdjsy6b31q9i0d73sl7xjd12xadbwi45lkpfgqnmasrqg5i3ych"))

(define rust-zerovec-derive-0.11.3
  (crate-source "zerovec-derive" "0.11.3"
                "0m85qj92mmfvhjra6ziqky5b1p4kcmp5069k7kfadp5hr8jw8pb2"))

(define rust-zlib-rs-0.5.5
  (crate-source "zlib-rs" "0.5.5"
                "1lxa1hf3bs8ip15jq8i8h9wdaaahcgxlzxvsj2vc5qmaa7fhx6a0"))

(define rust-zmij-1.0.21
  (crate-source "zmij" "1.0.21"
                "1amb5i6gz7yjb0dnmz5y669674pqmwbj44p4yfxfv2ncgvk8x15q"))

(define rust-zstd-0.13.3
  (crate-source "zstd" "0.13.3"
                "12n0h4w9l526li7jl972rxpyf012jw3nwmji2qbjghv9ll8y67p9"))

(define rust-zstd-safe-7.2.4
  (crate-source "zstd-safe" "7.2.4"
                "179vxmkzhpz6cq6mfzvgwc99bpgllkr6lwxq7ylh5dmby3aw8jcg"))

(define rust-zstd-sys-2.0.16+zstd.1.5.7
  (crate-source "zstd-sys" "2.0.16+zstd.1.5.7"
                "0j1pd2iaqpvaxlgqmmijj68wma7xwdv9grrr63j873yw5ay9xqci"
                #:snippet '(delete-file-recursively "zstd")))

(define rust-zune-core-0.4.12
  (crate-source "zune-core" "0.4.12"
                "0jj1ra86klzlcj9aha9als9d1dzs7pqv3azs1j3n96822wn3lhiz"))

(define rust-zune-core-0.5.1
  (crate-source "zune-core" "0.5.1"
                "1ya0zdqxlr5v57791j7bvm408ri2cfx81a4v6z85f560yw3hi2nb"))

(define rust-zune-inflate-0.2.54
  (crate-source "zune-inflate" "0.2.54"
                "00kg24jh3zqa3i6rg6yksnb71bch9yi1casqydl00s7nw8pk7avk"))

(define rust-zune-jpeg-0.4.21
  (crate-source "zune-jpeg" "0.4.21"
                "04r7g6y9jp7d4c9bq23rz3gwzlr1dsl7vdk4yly35bc4jf52rki9"))

(define rust-zune-jpeg-0.5.15
  (crate-source "zune-jpeg" "0.5.15"
                "15kjpn6pywxlwb8w5irfd68x31wi3mb4y1da8bqh7havh5drvg17"))


(define-cargo-inputs lookup-cargo-inputs
                     (pi =>
                         (list rust-addr2line-0.25.1
                               rust-addr2line-0.26.1
                               rust-adler2-2.0.1
                               rust-aead-0.5.2
                               rust-aes-0.8.4
                               rust-aes-gcm-0.10.3
                               rust-ahash-0.8.12
                               rust-aho-corasick-1.1.4
                               rust-aligned-0.4.3
                               rust-aligned-vec-0.6.4
                               rust-alloca-0.4.0
                               rust-allocator-api2-0.2.21
                               rust-android-system-properties-0.1.5
                               rust-anes-0.1.6
                               rust-anstream-1.0.0
                               rust-anstyle-1.0.14
                               rust-anstyle-parse-1.0.0
                               rust-anstyle-query-1.1.5
                               rust-anstyle-wincon-3.0.11
                               rust-anyhow-1.0.104
                               rust-ar-archive-writer-0.5.1
                               rust-arbitrary-1.4.2
                               rust-arboard-3.6.1
                               rust-arc-swap-1.9.1
                               rust-arg-enum-proc-macro-0.3.4
                               rust-arrayvec-0.7.6
                               rust-as-slice-0.2.1
                               rust-ascii-1.1.0
                               rust-asn1-rs-0.7.1
                               rust-asn1-rs-derive-0.6.0
                               rust-asn1-rs-impl-0.2.0
                               rust-ast-grep-core-0.40.5
                               rust-ast-grep-language-0.40.5
                               rust-ast-node-5.0.0
                               rust-asupersync-0.3.9
                               rust-async-lock-3.4.2
                               rust-async-trait-0.1.89
                               rust-autocfg-1.5.0
                               rust-av-scenechange-0.14.1
                               rust-av1-grain-0.2.5
                               rust-avif-serialize-0.8.8
                               rust-backtrace-0.3.76
                               rust-base64-0.22.1
                               rust-base64ct-1.8.3
                               rust-better-scoped-tls-1.0.1
                               rust-bincode-1.3.3
                               rust-bincode-next-3.1.1
                               rust-bincode-derive-next-3.1.1
                               rust-bindgen-0.72.1
                               rust-bit-set-0.8.0
                               rust-bit-vec-0.8.0
                               rust-bit-field-0.10.3
                               rust-bitflags-2.11.1
                               rust-bitstream-io-4.10.0
                               rust-block-buffer-0.10.4
                               rust-block-buffer-0.12.0
                               rust-block2-0.6.2
                               rust-borrow-or-share-0.2.4
                               rust-bstr-1.12.1
                               rust-built-0.8.0
                               rust-bumpalo-3.20.2
                               rust-bytecount-0.6.9
                               rust-bytemuck-1.25.0
                               rust-byteorder-1.5.0
                               rust-byteorder-lite-0.1.0
                               rust-bytes-1.11.1
                               rust-bytes-str-0.2.7
                               rust-camino-1.2.2
                               rust-cargo-platform-0.3.0
                               rust-cargo-metadata-0.23.1
                               rust-cast-0.3.0
                               rust-castaway-0.2.4
                               rust-cc-1.2.60
                               rust-cexpr-0.6.0
                               rust-cfg-if-1.0.4
                               rust-cfg-aliases-0.2.1
                               rust-chacha20-0.9.1
                               rust-chacha20poly1305-0.10.1
                               rust-charmed-bubbles-0.2.0
                               rust-charmed-bubbletea-0.2.0
                               rust-charmed-bubbletea-macros-0.2.0
                               rust-charmed-glamour-0.2.0
                               rust-charmed-harmonica-0.2.0
                               rust-charmed-lipgloss-0.2.0
                               rust-chrono-0.4.44
                               rust-ciborium-0.2.2
                               rust-ciborium-io-0.2.2
                               rust-ciborium-ll-0.2.2
                               rust-cipher-0.4.4
                               rust-clang-sys-1.8.1
                               rust-clap-4.6.1
                               rust-clap-builder-4.6.0
                               rust-clap-complete-4.6.2
                               rust-clap-derive-4.6.1
                               rust-clap-lex-1.1.0
                               rust-clipboard-win-5.4.1
                               rust-clru-0.6.3
                               rust-cmov-0.5.3
                               rust-cobs-0.3.0
                               rust-color-quant-1.1.0
                               rust-colorchoice-1.0.5
                               rust-colored-2.2.0
                               rust-compact-str-0.7.1
                               rust-concurrent-queue-2.5.0
                               rust-console-0.16.3
                               rust-const-oid-0.9.6
                               rust-const-oid-0.10.2
                               rust-convert-case-0.10.0
                               rust-core-foundation-sys-0.8.7
                               rust-cpp-demangle-0.5.1
                               rust-cpufeatures-0.2.17
                               rust-cpufeatures-0.3.0
                               rust-cranelift-assembler-x64-0.134.3
                               rust-cranelift-assembler-x64-meta-0.134.3
                               rust-cranelift-bforest-0.134.3
                               rust-cranelift-bitset-0.134.3
                               rust-cranelift-codegen-0.134.3
                               rust-cranelift-codegen-meta-0.134.3
                               rust-cranelift-codegen-shared-0.134.3
                               rust-cranelift-control-0.134.3
                               rust-cranelift-entity-0.134.3
                               rust-cranelift-frontend-0.134.3
                               rust-cranelift-isle-0.134.3
                               rust-cranelift-native-0.134.3
                               rust-cranelift-srcgen-0.134.3
                               rust-crc32c-0.6.8
                               rust-crc32fast-1.5.0
                               rust-criterion-0.8.2
                               rust-criterion-plot-0.8.2
                               rust-crossbeam-deque-0.8.6
                               rust-crossbeam-epoch-0.9.20
                               rust-crossbeam-queue-0.3.12
                               rust-crossbeam-utils-0.8.21
                               rust-crossterm-0.29.0
                               rust-crossterm-winapi-0.9.1
                               rust-crunchy-0.2.4
                               rust-crypto-common-0.1.7
                               rust-crypto-common-0.2.1
                               rust-ctr-0.9.2
                               rust-ctrlc-3.5.2
                               rust-ctutils-0.4.2
                               rust-curve25519-dalek-4.1.3
                               rust-curve25519-dalek-derive-0.1.1
                               rust-darling-0.20.11
                               rust-darling-core-0.20.11
                               rust-darling-macro-0.20.11
                               rust-dashmap-6.1.0
                               rust-data-encoding-2.10.0
                               rust-debugid-0.8.0
                               rust-der-0.7.10
                               rust-der-parser-10.0.0
                               rust-deranged-0.5.8
                               rust-derive-arbitrary-1.4.2
                               rust-derive-builder-0.20.2
                               rust-derive-builder-core-0.20.2
                               rust-derive-builder-macro-0.20.2
                               rust-derive-more-2.1.1
                               rust-derive-more-impl-2.1.1
                               rust-diff-0.1.13
                               rust-digest-0.10.7
                               rust-digest-0.11.2
                               rust-directories-next-2.0.0
                               rust-dirs-6.0.0
                               rust-dirs-sys-0.5.0
                               rust-dirs-sys-next-0.1.2
                               rust-dispatch2-0.3.1
                               rust-displaydoc-0.2.5
                               rust-document-features-0.2.12
                               rust-dragonbox-ecma-0.1.12
                               rust-dunce-1.0.5
                               rust-ed25519-2.2.3
                               rust-ed25519-dalek-2.2.0
                               rust-either-1.15.0
                               rust-email-address-0.2.9
                               rust-embedded-io-0.4.0
                               rust-embedded-io-0.6.1
                               rust-enable-ansi-support-0.2.1
                               rust-encode-unicode-1.0.0
                               rust-encoding-rs-0.8.35
                               rust-equator-0.4.2
                               rust-equator-macro-0.4.2
                               rust-equivalent-1.0.2
                               rust-errno-0.3.14
                               rust-error-code-3.3.2
                               rust-event-listener-5.4.2
                               rust-event-listener-strategy-0.5.4
                               rust-exr-1.74.0
                               rust-fancy-regex-0.17.0
                               rust-faster-hex-0.10.0
                               rust-fastrand-2.4.1
                               rust-fax-0.2.6
                               rust-fax-derive-0.2.0
                               rust-fdeflate-0.3.7
                               rust-fiat-crypto-0.2.9
                               rust-filetime-0.2.27
                               rust-find-msvc-tools-0.1.9
                               rust-fixedbitset-0.4.2
                               rust-flate2-1.1.9
                               rust-fluent-uri-0.4.1
                               rust-fnv-1.0.7
                               rust-foldhash-0.1.5
                               rust-foldhash-0.2.0
                               rust-form-urlencoded-1.2.2
                               rust-fraction-0.15.4
                               rust-franken-decision-0.3.9
                               rust-franken-evidence-0.3.9
                               rust-franken-kernel-0.3.9
                               rust-from-variant-3.0.0
                               rust-fs4-0.13.1
                               rust-futures-0.3.32
                               rust-futures-channel-0.3.32
                               rust-futures-core-0.3.32
                               rust-futures-executor-0.3.32
                               rust-futures-io-0.3.32
                               rust-futures-lite-2.6.1
                               rust-futures-macro-0.3.32
                               rust-futures-sink-0.3.32
                               rust-futures-task-0.3.32
                               rust-futures-util-0.3.32
                               rust-fxprof-processed-profile-0.8.1
                               rust-generator-0.8.8
                               rust-generic-array-0.14.7
                               rust-gethostname-1.1.0
                               rust-getopts-0.2.24
                               rust-getrandom-0.2.17
                               rust-getrandom-0.3.4
                               rust-getrandom-0.4.2
                               rust-ghash-0.5.1
                               rust-gif-0.14.2
                               rust-gimli-0.32.3
                               rust-gimli-0.33.0
                               rust-gix-0.77.0
                               rust-gix-actor-0.37.1
                               rust-gix-attributes-0.29.0
                               rust-gix-bitmap-0.2.16
                               rust-gix-chunk-0.4.12
                               rust-gix-command-0.6.5
                               rust-gix-commitgraph-0.31.0
                               rust-gix-config-0.50.0
                               rust-gix-config-value-0.16.0
                               rust-gix-date-0.12.1
                               rust-gix-diff-0.57.1
                               rust-gix-dir-0.19.0
                               rust-gix-discover-0.45.0
                               rust-gix-features-0.45.2
                               rust-gix-filter-0.24.1
                               rust-gix-fs-0.18.2
                               rust-gix-glob-0.23.0
                               rust-gix-hash-0.21.2
                               rust-gix-hashtable-0.11.0
                               rust-gix-ignore-0.18.0
                               rust-gix-index-0.45.1
                               rust-gix-lock-20.0.1
                               rust-gix-object-0.54.1
                               rust-gix-odb-0.74.0
                               rust-gix-pack-0.64.1
                               rust-gix-packetline-0.20.0
                               rust-gix-path-0.10.22
                               rust-gix-pathspec-0.14.0
                               rust-gix-protocol-0.55.0
                               rust-gix-quote-0.6.2
                               rust-gix-ref-0.57.0
                               rust-gix-refspec-0.35.0
                               rust-gix-revision-0.39.0
                               rust-gix-revwalk-0.25.0
                               rust-gix-sec-0.12.2
                               rust-gix-shallow-0.7.0
                               rust-gix-status-0.24.0
                               rust-gix-submodule-0.24.0
                               rust-gix-tempfile-20.0.1
                               rust-gix-trace-0.1.18
                               rust-gix-transport-0.52.1
                               rust-gix-traverse-0.51.1
                               rust-gix-url-0.34.0
                               rust-gix-utils-0.3.1
                               rust-gix-validate-0.10.1
                               rust-gix-worktree-0.46.0
                               rust-glob-0.3.3
                               rust-globset-0.4.18
                               rust-half-2.7.1
                               rust-hash32-0.3.1
                               rust-hashbrown-0.14.5
                               rust-hashbrown-0.15.5
                               rust-hashbrown-0.16.1
                               rust-hashbrown-0.17.0
                               rust-heapless-0.8.0
                               rust-heck-0.5.0
                               rust-hermit-abi-0.5.2
                               rust-hex-0.4.3
                               rust-hkdf-0.13.0
                               rust-hmac-0.12.1
                               rust-hmac-0.13.0
                               rust-hstr-3.0.4
                               rust-hybrid-array-0.4.10
                               rust-iana-time-zone-0.1.65
                               rust-iana-time-zone-haiku-0.1.2
                               rust-icu-collections-2.1.1
                               rust-icu-locale-core-2.1.1
                               rust-icu-normalizer-2.1.1
                               rust-icu-normalizer-data-2.1.1
                               rust-icu-properties-2.1.2
                               rust-icu-properties-data-2.1.2
                               rust-icu-provider-2.1.1
                               rust-id-arena-2.3.0
                               rust-ident-case-1.0.1
                               rust-idna-1.1.0
                               rust-idna-adapter-1.2.1
                               rust-ignore-0.4.25
                               rust-image-0.25.9
                               rust-image-webp-0.2.4
                               rust-imara-diff-0.1.8
                               rust-imgref-1.12.0
                               rust-indexmap-2.14.0
                               rust-inout-0.1.4
                               rust-insta-1.47.2
                               rust-interpolate-name-0.2.4
                               rust-is-macro-0.3.7
                               rust-is-terminal-polyfill-1.70.2
                               rust-itertools-0.13.0
                               rust-itertools-0.14.0
                               rust-itoa-1.0.18
                               rust-ittapi-0.4.0
                               rust-ittapi-sys-0.4.0
                               rust-jiff-0.2.23
                               rust-jiff-static-0.2.23
                               rust-jiff-tzdb-0.1.6
                               rust-jiff-tzdb-platform-0.1.3
                               rust-jobserver-0.1.34
                               rust-js-sys-0.3.95
                               rust-json5-1.3.1
                               rust-jsonschema-0.42.2
                               rust-kstring-2.0.2
                               rust-lazy-static-1.5.0
                               rust-leb128fmt-0.1.0
                               rust-lebe-0.5.3
                               rust-libc-0.2.185
                               rust-libfuzzer-sys-0.4.12
                               rust-libloading-0.8.9
                               rust-libm-0.2.16
                               rust-libredox-0.1.16
                               rust-libsqlite3-sys-0.37.0
                               rust-linked-hash-map-0.5.6
                               rust-linux-raw-sys-0.12.1
                               rust-litemap-0.8.2
                               rust-litrs-1.0.0
                               rust-lock-api-0.4.14
                               rust-log-0.4.29
                               rust-loom-0.7.2.2b7c402
                               rust-loop9-0.1.5
                               rust-lru-0.12.5
                               rust-lru-0.16.4
                               rust-mach2-0.6.0
                               rust-matchers-0.2.0
                               rust-maybe-async-0.2.10
                               rust-maybe-rayon-0.1.1
                               rust-md-5-0.10.6
                               rust-memchr-2.8.0
                               rust-memfd-0.6.5
                               rust-memmap2-0.9.11
                               rust-memoffset-0.9.1
                               rust-minimal-lexical-0.2.1
                               rust-miniz-oxide-0.8.9
                               rust-mio-1.2.0
                               rust-moxcms-0.7.11
                               rust-new-debug-unreachable-1.0.6
                               rust-nix-0.31.2
                               rust-nkeys-0.4.5
                               rust-no-std-io2-0.9.3
                               rust-nom-7.1.3
                               rust-nom-8.0.0
                               rust-noop-proc-macro-0.3.0
                               rust-ntapi-0.4.3
                               rust-nu-ansi-term-0.50.3
                               rust-num-0.4.3
                               rust-num-bigint-0.4.6
                               rust-num-cmp-0.1.0
                               rust-num-complex-0.4.6
                               rust-num-conv-0.2.1
                               rust-num-derive-0.4.2
                               rust-num-integer-0.1.46
                               rust-num-iter-0.1.45
                               rust-num-rational-0.4.2
                               rust-num-traits-0.2.19
                               rust-num-cpus-1.17.0
                               rust-num-threads-0.1.7
                               rust-objc2-0.6.4
                               rust-objc2-app-kit-0.3.2
                               rust-objc2-core-foundation-0.3.2
                               rust-objc2-core-graphics-0.3.2
                               rust-objc2-encode-4.1.0
                               rust-objc2-foundation-0.3.2
                               rust-objc2-io-kit-0.3.2
                               rust-objc2-io-surface-0.3.2
                               rust-objc2-open-directory-0.3.2
                               rust-object-0.37.3
                               rust-object-0.39.1
                               rust-oid-registry-0.8.1
                               rust-once-cell-1.21.4
                               rust-once-cell-polyfill-1.70.2
                               rust-onig-6.5.1
                               rust-onig-sys-69.9.1
                               rust-oorandom-11.1.5
                               rust-opaque-debug-0.3.1
                               rust-option-ext-0.2.0
                               rust-os-pipe-1.2.3
                               rust-outref-0.5.2
                               rust-page-size-0.6.0
                               rust-par-core-2.0.0
                               rust-parking-2.2.1
                               rust-parking-lot-0.12.5
                               rust-parking-lot-core-0.9.12
                               rust-paste-1.0.15
                               rust-pastey-0.1.1
                               rust-pastey-0.2.3
                               rust-pbkdf2-0.12.2
                               rust-pem-rfc7468-0.7.0
                               rust-percent-encoding-2.3.2
                               rust-petgraph-0.6.5
                               rust-phf-0.11.3
                               rust-phf-generator-0.11.3
                               rust-phf-macros-0.11.3
                               rust-phf-shared-0.11.3
                               rust-pin-project-1.1.11
                               rust-pin-project-internal-1.1.11
                               rust-pin-project-lite-0.2.17
                               rust-pkcs8-0.10.2
                               rust-pkg-config-0.3.33
                               rust-plain-0.2.3
                               rust-plist-1.10.0
                               rust-plotters-0.3.7
                               rust-plotters-backend-0.3.7
                               rust-plotters-svg-0.3.7
                               rust-png-0.18.1
                               rust-polling-3.11.0
                               rust-poly1305-0.8.0
                               rust-polyval-0.6.2
                               rust-portable-atomic-1.13.1
                               rust-portable-atomic-util-0.2.7
                               rust-postcard-1.1.3
                               rust-potential-utf-0.1.5
                               rust-powerfmt-0.2.0
                               rust-ppv-lite86-0.2.21
                               rust-pretty-assertions-1.4.1
                               rust-prettyplease-0.2.37
                               rust-proc-macro-crate-3.5.0
                               rust-proc-macro-error-attr2-2.0.0
                               rust-proc-macro-error2-2.0.1
                               rust-proc-macro2-1.0.106
                               rust-prodash-30.0.1
                               rust-profiling-1.0.17
                               rust-profiling-procmacros-1.0.17
                               rust-proptest-1.11.0
                               rust-prost-0.14.3
                               rust-prost-derive-0.14.3
                               rust-psm-0.1.30
                               rust-pulldown-cmark-0.13.3
                               rust-pulldown-cmark-escape-0.11.0
                               rust-pulley-interpreter-47.0.3
                               rust-pulley-macros-47.0.3
                               rust-pxfm-0.1.29
                               rust-qoi-0.4.1
                               rust-quick-error-1.2.3
                               rust-quick-error-2.0.1
                               rust-quick-xml-0.41.0
                               rust-quote-1.0.45
                               rust-r-efi-5.3.0
                               rust-r-efi-6.0.0
                               rust-rand-0.8.6
                               rust-rand-0.9.4
                               rust-rand-chacha-0.3.1
                               rust-rand-chacha-0.9.0
                               rust-rand-core-0.6.4
                               rust-rand-core-0.9.5
                               rust-rand-xorshift-0.4.0
                               rust-rapidhash-4.5.1
                               rust-rav1e-0.8.1
                               rust-ravif-0.12.0
                               rust-rayon-1.12.0
                               rust-rayon-core-1.13.0
                               rust-redox-syscall-0.5.18
                               rust-redox-syscall-0.7.4
                               rust-redox-users-0.4.6
                               rust-redox-users-0.5.2
                               rust-ref-cast-1.0.25
                               rust-ref-cast-impl-1.0.25
                               rust-referencing-0.42.2
                               rust-regalloc2-0.15.2
                               rust-regex-1.12.3
                               rust-regex-automata-0.4.14
                               rust-regex-syntax-0.8.10
                               rust-relative-path-2.0.1
                               rust-rgb-0.8.53
                               rust-rich-rust-0.2.2
                               rust-ring-0.17.14
                               rust-rmp-0.8.15
                               rust-rmp-serde-1.3.1
                               rust-rquickjs-0.11.0
                               rust-rquickjs-core-0.11.0
                               rust-rquickjs-macro-0.11.0
                               rust-rquickjs-sys-0.11.0
                               rust-rustc-demangle-0.1.27
                               rust-rustc-hash-2.1.2
                               rust-rustc-version-0.4.1
                               rust-rusticata-macros-4.1.0
                               rust-rustix-1.1.4
                               rust-rustls-0.23.40
                               rust-rustls-pemfile-2.2.0
                               rust-rustls-pki-types-1.14.1
                               rust-rustls-webpki-0.103.13
                               rust-rustversion-1.0.22
                               rust-rusty-fork-0.3.1
                               rust-ryu-1.0.23
                               rust-salsa20-0.10.2
                               rust-same-file-1.0.6
                               rust-scoped-tls-1.0.1
                               rust-scopeguard-1.2.0
                               rust-scrypt-0.11.0
                               rust-semver-1.0.28
                               rust-seq-macro-0.3.6
                               rust-serde-1.0.228
                               rust-serde-core-1.0.228
                               rust-serde-derive-1.0.228
                               rust-serde-json-1.0.149
                               rust-serde-spanned-0.6.9
                               rust-serde-spanned-1.1.1
                               rust-sha1-0.10.6
                               rust-sha1-0.11.0
                               rust-sha1-checked-0.10.0
                               rust-sha2-0.10.9
                               rust-sha2-0.11.0
                               rust-sharded-slab-0.1.7
                               rust-shell-words-1.1.1
                               rust-shlex-1.3.0
                               rust-signal-hook-0.3.18
                               rust-signal-hook-0.4.4
                               rust-signal-hook-mio-0.2.5
                               rust-signal-hook-registry-1.4.8
                               rust-signatory-0.27.1
                               rust-signature-2.2.0
                               rust-simd-adler32-0.3.9
                               rust-simd-helpers-0.1.0
                               rust-similar-2.7.0
                               rust-siphasher-0.3.11
                               rust-siphasher-1.0.2
                               rust-slab-0.4.12
                               rust-smallvec-1.15.1
                               rust-smartstring-1.0.1
                               rust-smawk-0.3.2
                               rust-socket2-0.6.3
                               rust-spki-0.7.3
                               rust-sqlmodel-core-0.2.2
                               rust-sqlmodel-sqlite-0.2.2
                               rust-stable-deref-trait-1.2.1
                               rust-stacker-0.1.23
                               rust-static-assertions-1.1.0
                               rust-stdio-override-0.2.0
                               rust-streaming-iterator-0.1.9
                               rust-string-enum-1.0.2
                               rust-strsim-0.11.1
                               rust-subtle-2.6.1
                               rust-swc-allocator-4.0.1
                               rust-swc-atoms-9.0.0
                               rust-swc-common-18.0.1
                               rust-swc-config-3.1.2
                               rust-swc-config-macro-1.0.1
                               rust-swc-ecma-ast-20.0.1
                               rust-swc-ecma-codegen-23.0.0
                               rust-swc-ecma-codegen-macros-2.0.2
                               rust-swc-ecma-hooks-0.4.0
                               rust-swc-ecma-parser-34.0.0
                               rust-swc-ecma-transforms-base-37.0.0
                               rust-swc-ecma-transforms-react-41.0.1
                               rust-swc-ecma-transforms-typescript-41.0.0
                               rust-swc-ecma-utils-26.0.1
                               rust-swc-ecma-visit-20.0.0
                               rust-swc-eq-ignore-macros-1.0.1
                               rust-swc-macros-common-1.0.1
                               rust-swc-visit-2.0.1
                               rust-syn-2.0.117
                               rust-synstructure-0.13.2
                               rust-syntect-5.3.0
                               rust-sysinfo-0.39.6
                               rust-target-lexicon-0.13.5
                               rust-tempfile-3.27.0
                               rust-termcolor-1.4.1
                               rust-textwrap-0.16.2
                               rust-thiserror-1.0.69
                               rust-thiserror-2.0.18
                               rust-thiserror-impl-1.0.69
                               rust-thiserror-impl-2.0.18
                               rust-thread-local-1.1.9
                               rust-tiff-0.10.3
                               rust-tikv-jemalloc-sys-0.6.1+5.3.0-1-ge13ca993e8ccb9ba9847cc330696e02839f328f7
                               rust-tikv-jemallocator-0.6.1
                               rust-time-0.3.47
                               rust-time-core-0.1.8
                               rust-time-macros-0.2.27
                               rust-tinystr-0.8.3
                               rust-tinytemplate-1.2.1
                               rust-tinyvec-1.11.0
                               rust-tinyvec-macros-0.1.1
                               rust-toml-0.8.23
                               rust-toml-0.9.12+spec-1.1.0
                               rust-toml-1.1.2+spec-1.1.0
                               rust-toml-datetime-0.6.11
                               rust-toml-datetime-0.7.5+spec-1.1.0
                               rust-toml-datetime-1.1.1+spec-1.1.0
                               rust-toml-edit-0.22.27
                               rust-toml-edit-0.25.11+spec-1.1.0
                               rust-toml-parser-1.1.2+spec-1.1.0
                               rust-toml-write-0.1.2
                               rust-toml-writer-1.1.1+spec-1.1.0
                               rust-tracing-0.1.44
                               rust-tracing-attributes-0.1.31
                               rust-tracing-core-0.1.36
                               rust-tracing-log-0.2.0
                               rust-tracing-subscriber-0.3.23
                               rust-tree-sitter-0.26.8
                               rust-tree-sitter-bash-0.25.1
                               rust-tree-sitter-javascript-0.25.0
                               rust-tree-sitter-language-0.1.7
                               rust-tree-sitter-python-0.25.0
                               rust-tree-sitter-ruby-0.23.1
                               rust-tree-sitter-typescript-0.23.2
                               rust-triomphe-0.1.15
                               rust-typenum-1.20.0
                               rust-ucd-trie-0.1.7
                               rust-unarray-0.1.4
                               rust-unicase-2.9.0
                               rust-unicode-bom-2.0.3
                               rust-unicode-general-category-1.1.0
                               rust-unicode-id-start-1.4.0
                               rust-unicode-ident-1.0.24
                               rust-unicode-linebreak-0.1.5
                               rust-unicode-normalization-0.1.25
                               rust-unicode-segmentation-1.13.2
                               rust-unicode-width-0.1.14
                               rust-unicode-width-0.2.2
                               rust-unicode-xid-0.2.6
                               rust-universal-hash-0.5.1
                               rust-untrusted-0.9.0
                               rust-unty-next-0.1.2
                               rust-url-2.5.8
                               rust-utf8-iter-1.0.4
                               rust-utf8parse-0.2.2
                               rust-uuid-1.23.1
                               rust-uuid-simd-0.8.0
                               rust-v-frame-0.3.9
                               rust-valuable-0.1.1
                               rust-vcpkg-0.2.15
                               rust-vergen-9.1.0
                               rust-vergen-gix-9.1.0
                               rust-vergen-lib-9.1.0
                               rust-version-check-0.9.5
                               rust-virtue-next-0.1.3
                               rust-visibility-0.1.1
                               rust-vsimd-0.8.0
                               rust-wait-timeout-0.2.1
                               rust-walkdir-2.5.0
                               rust-wasi-0.11.1+wasi-snapshot-preview1
                               rust-wasip2-1.0.1+wasi-0.2.4
                               rust-wasip3-0.4.0+wasi-0.3.0-rc-2026-01-06
                               rust-wasm-bindgen-0.2.118
                               rust-wasm-bindgen-futures-0.4.68
                               rust-wasm-bindgen-macro-0.2.118
                               rust-wasm-bindgen-macro-support-0.2.118
                               rust-wasm-bindgen-shared-0.2.118
                               rust-wasm-compose-0.252.0
                               rust-wasm-encoder-0.244.0
                               rust-wasm-encoder-0.252.0
                               rust-wasm-encoder-0.255.0
                               rust-wasm-metadata-0.244.0
                               rust-wasmparser-0.244.0
                               rust-wasmparser-0.252.0
                               rust-wasmparser-0.255.0
                               rust-wasmprinter-0.252.0
                               rust-wasmtime-47.0.3
                               rust-wasmtime-environ-47.0.3
                               rust-wasmtime-internal-cache-47.0.3
                               rust-wasmtime-internal-component-macro-47.0.3
                               rust-wasmtime-internal-component-util-47.0.3
                               rust-wasmtime-internal-core-47.0.3
                               rust-wasmtime-internal-cranelift-47.0.3
                               rust-wasmtime-internal-fiber-47.0.3
                               rust-wasmtime-internal-jit-debug-47.0.3
                               rust-wasmtime-internal-jit-icache-coherence-47.0.3
                               rust-wasmtime-internal-unwinder-47.0.3
                               rust-wasmtime-internal-versioned-export-macros-47.0.3
                               rust-wasmtime-internal-wit-bindgen-47.0.3
                               rust-wast-255.0.0
                               rust-wat-1.255.0
                               rust-web-sys-0.3.95
                               rust-webpki-roots-1.0.7
                               rust-weezl-0.1.12
                               rust-winapi-0.3.9
                               rust-winapi-i686-pc-windows-gnu-0.4.0
                               rust-winapi-util-0.1.11
                               rust-winapi-x86-64-pc-windows-gnu-0.4.0
                               rust-windows-0.62.2
                               rust-windows-collections-0.3.2
                               rust-windows-core-0.62.2
                               rust-windows-future-0.3.2
                               rust-windows-implement-0.60.2
                               rust-windows-interface-0.59.3
                               rust-windows-link-0.2.1
                               rust-windows-numerics-0.3.1
                               rust-windows-result-0.4.1
                               rust-windows-strings-0.5.1
                               rust-windows-sys-0.42.0
                               rust-windows-sys-0.52.0
                               rust-windows-sys-0.59.0
                               rust-windows-sys-0.60.2
                               rust-windows-sys-0.61.2
                               rust-windows-targets-0.52.6
                               rust-windows-targets-0.53.5
                               rust-windows-threading-0.2.1
                               rust-windows-aarch64-gnullvm-0.42.2
                               rust-windows-aarch64-gnullvm-0.52.6
                               rust-windows-aarch64-gnullvm-0.53.1
                               rust-windows-aarch64-msvc-0.42.2
                               rust-windows-aarch64-msvc-0.52.6
                               rust-windows-aarch64-msvc-0.53.1
                               rust-windows-i686-gnu-0.42.2
                               rust-windows-i686-gnu-0.52.6
                               rust-windows-i686-gnu-0.53.1
                               rust-windows-i686-gnullvm-0.52.6
                               rust-windows-i686-gnullvm-0.53.1
                               rust-windows-i686-msvc-0.42.2
                               rust-windows-i686-msvc-0.52.6
                               rust-windows-i686-msvc-0.53.1
                               rust-windows-x86-64-gnu-0.42.2
                               rust-windows-x86-64-gnu-0.52.6
                               rust-windows-x86-64-gnu-0.53.1
                               rust-windows-x86-64-gnullvm-0.42.2
                               rust-windows-x86-64-gnullvm-0.52.6
                               rust-windows-x86-64-gnullvm-0.53.1
                               rust-windows-x86-64-msvc-0.42.2
                               rust-windows-x86-64-msvc-0.52.6
                               rust-windows-x86-64-msvc-0.53.1
                               rust-winnow-0.7.15
                               rust-winnow-1.0.2
                               rust-wit-bindgen-0.46.0
                               rust-wit-bindgen-0.51.0
                               rust-wit-bindgen-core-0.51.0
                               rust-wit-bindgen-rust-0.51.0
                               rust-wit-bindgen-rust-macro-0.51.0
                               rust-wit-component-0.244.0
                               rust-wit-parser-0.244.0
                               rust-wit-parser-0.252.0
                               rust-writeable-0.6.3
                               rust-x11rb-0.13.2
                               rust-x11rb-protocol-0.13.2
                               rust-x509-parser-0.18.1
                               rust-xattr-1.6.1
                               rust-xxhash-rust-0.8.15
                               rust-y4m-0.8.0
                               rust-yaml-rust-0.4.5
                               rust-yansi-1.0.1
                               rust-yoke-0.8.2
                               rust-yoke-derive-0.8.2
                               rust-zerocopy-0.8.48
                               rust-zerocopy-derive-0.8.48
                               rust-zerofrom-0.1.7
                               rust-zerofrom-derive-0.1.7
                               rust-zeroize-1.8.2
                               rust-zeroize-derive-1.4.3
                               rust-zerotrie-0.2.4
                               rust-zerovec-0.11.6
                               rust-zerovec-derive-0.11.3
                               rust-zlib-rs-0.5.5
                               rust-zmij-1.0.21
                               rust-zstd-0.13.3
                               rust-zstd-safe-7.2.4
                               rust-zstd-sys-2.0.16+zstd.1.5.7
                               rust-zune-core-0.4.12
                               rust-zune-core-0.5.1
                               rust-zune-inflate-0.2.54
                               rust-zune-jpeg-0.4.21
                               rust-zune-jpeg-0.5.15)))
