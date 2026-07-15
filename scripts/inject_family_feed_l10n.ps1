$arbDir = 'lib/l10n'

# Per-locale values for the family-feed block.
# Each `FeedLikeCount` template uses PowerShell escape sequence
# `{{` for literal `{` inside the JSON value — escaped here so the
# script block syntax doesn't trip up the CJK-heavy templates.

$block = @{
  'en'      = @{ F1='No moments yet'; F2='Post the first update for your family.'; F3="Couldn't load more"; F4='Delete this update?'; F5='This update will be removed for everyone.'; F6='Delete'; F7='Update deleted'; F8='Like'; F9='Liked'; F10='{count, plural, =0{0 likes} =1{1 like} other{{count} likes}}'; F11='{count} more'; F12='No comments yet'; F13='Comments are on the way'; P1='New update'; P2="What's happening?"; P3='Share a thought, a photo, or a moment from your day.'; P4='Please write something or add a photo'; P5='Add media'; P6='Photo'; P7='Video'; P8='Voice'; P9='Add to your post'; P10='Up to 9 files per post'; P11='Remove'; P12='Tap to record'; P13='Tap to stop'; P14='Cancel'; P15='Hold for a bit longer'; P16="Couldn't record audio"; P17='Allow microphone access to add a voice clip'; P18='Post'; P19='Posting…'; P20='Posted'; P21="Couldn't post — try again"; P22='Uploading {current}/{total}…'; P23='Discard this post?'; P24='Your changes will be lost.'; P25='Discard'; P26='Keep editing'; D1='Update'; D2='Likes'; D3='Be the first to like this'; D4='Play video'; D5="Couldn't load video"; D6='Play'; D7='Pause'; FB='Post' }
  'zh'      = @{ F1='还没有动态'; F2='发一条，让家里人多一点回忆。'; F3='加载更多失败'; F4='删除这条动态？'; F5='删除后家里所有人都看不到。'; F6='删除'; F7='动态已删除'; F8='赞'; F9='已赞'; F10='{count, plural, =0{0 人觉得赞} other{{count} 人觉得很赞}}'; F11='还有 {count} 人'; F12='还没有评论'; F13='评论功能即将上线'; P1='发动态'; P2='说点什么…'; P3='一张照片，一段心情，都是家里的记忆。'; P4='写点儿内容或者加张照片再发布吧'; P5='添加'; P6='照片'; P7='视频'; P8='语音'; P9='添加到动态'; P10='最多 9 个文件'; P11='移除'; P12='点击开始录音'; P13='点击结束'; P14='取消'; P15='再长一点点吧'; P16='录音失败'; P17='需要麦克风权限才能录制语音'; P18='发布'; P19='发布中…'; P20='发布成功'; P21='发布失败，请重试'; P22='正在上传 {current}/{total}…'; P23='放弃这条动态？'; P24='当前编辑将丢失。'; P25='放弃'; P26='继续编辑'; D1='动态详情'; D2='点赞列表'; D3='抢个沙发吧'; D4='播放视频'; D5='视频加载失败'; D6='播放'; D7='暂停'; FB='发布' }
  'zh_Hans' = @{ F1='还没有动态'; F2='发一条，让家里人多一点回忆。'; F3='加载更多失败'; F4='删除这条动态？'; F5='删除后家里所有人都看不到。'; F6='删除'; F7='动态已删除'; F8='赞'; F9='已赞'; F10='{count, plural, =0{0 人觉得很赞} other{{count} 人觉得很赞}}'; F11='还有 {count} 人'; F12='还没有评论'; F13='评论功能即将上线'; P1='发动态'; P2='说点什么…'; P3='一张照片，一段心情，都是家里的记忆。'; P4='写点儿内容或者加张照片再发布吧'; P5='添加'; P6='照片'; P7='视频'; P8='语音'; P9='添加到动态'; P10='最多 9 个文件'; P11='移除'; P12='点击开始录音'; P13='点击结束'; P14='取消'; P15='再长一点点吧'; P16='录音失败'; P17='需要麦克风权限才能录制语音'; P18='发布'; P19='发布中…'; P20='发布成功'; P21='发布失败，请重试'; P22='正在上传 {current}/{total}…'; P23='放弃这条动态？'; P24='当前编辑将丢失。'; P25='放弃'; P26='继续编辑'; D1='动态详情'; D2='点赞列表'; D3='抢个沙发吧'; D4='播放视频'; D5='视频加载失败'; D6='播放'; D7='暂停'; FB='发布' }
  'zh_Hant' = @{ F1='還沒有動態'; F2='發一條，讓家裡人多一點回憶。'; F3='載入更多失敗'; F4='刪除這條動態？'; F5='刪除後家裡所有人都看不到。'; F6='刪除'; F7='動態已刪除'; F8='讚'; F9='已讚'; F10='{count, plural, =0{0 人覺得讚} other{{count} 人覺得很讚}}'; F11='還有 {count} 人'; F12='還沒有評論'; F13='評論功能即將上線'; P1='發動態'; P2='說點什麼…'; P3='一張照片，一段心情，都是家裡的記憶。'; P4='寫點兒內容或者加張照片再發佈吧'; P5='新增'; P6='照片'; P7='影片'; P8='語音'; P9='新增到動態'; P10='最多 9 個檔案'; P11='移除'; P12='點擊開始錄音'; P13='點擊結束'; P14='取消'; P15='再長一點點吧'; P16='錄音失敗'; P17='需要麥克風權限才能錄製語音'; P18='發佈'; P19='發佈中…'; P20='發佈成功'; P21='發佈失敗，請重試'; P22='正在上傳 {current}/{total}…'; P23='放棄這條動態？'; P24='目前編輯將遺失。'; P25='放棄'; P26='繼續編輯'; D1='動態詳情'; D2='點讚列表'; D3='搶個沙發吧'; D4='播放影片'; D5='影片載入失敗'; D6='播放'; D7='暫停'; FB='發佈' }
  'ja'      = @{ F1='まだ投稿がありません'; F2='最初の投稿を家族にシェアしましょう。'; F3='もっと読み込めませんでした'; F4='この投稿を削除しますか？'; F5='削除すると、家族の誰もが見られなくなります。'; F6='削除'; F7='投稿を削除しました'; F8='いいね'; F9='いいね済み'; F10='{count, plural, =0{0 いいね} other{いいね {count}件}}'; F11='他 {count} 名'; F12='まだコメントはありません'; F13='コメント機能は近日公開'; P1='新しい投稿'; P2='いま何してる？'; P3='写真でも気持ちでも、家族の思い出を残しましょう。'; P4='内容を入力するか、写真を追加してください'; P5='メディアを追加'; P6='写真'; P7='動画'; P8='音声'; P9='投稿に追加'; P10='最大9ファイルまで'; P11='削除'; P12='タップして録音'; P13='タップで停止'; P14='キャンセル'; P15='もう少し長めに録音してください'; P16='録音を保存できませんでした'; P17='音声を追加するにはマイクへのアクセス許可が必要です'; P18='投稿'; P19='投稿中…'; P20='投稿しました'; P21='投稿に失敗しました。もう一度お試しください'; P22='アップロード中 {current}/{total}…'; P23='この投稿を破棄しますか？'; P24='編集中の内容は失われます。'; P25='破棄'; P26='編集を続ける'; D1='投稿'; D2='いいね'; D3='最初のいいねをしよう'; D4='動画を再生'; D5='動画を読み込めませんでした'; D6='再生'; D7='一時停止'; FB='投稿' }
  'ko'      = @{ F1='아직 게시글이 없어요'; F2='가족에 첫 게시글을 올려보세요.'; F3='더 불러오기 실패'; F4='이 게시글을 삭제할까요?'; F5='삭제하면 가족 모두가 더 이상 볼 수 없어요.'; F6='삭제'; F7='게시글이 삭제되었어요'; F8='좋아요'; F9='좋아요 취소'; F10='{count, plural, =0{좋아요 0개} other{좋아요 {count}개}}'; F11='{count}명 더'; F12='아직 댓글이 없어요'; F13='댓글 기능은 곧 추가돼요'; P1='새 게시글'; P2='무슨 일이 있나요?'; P3='사진이든 마음이든, 가족과 나눠보세요.'; P4='내용을 입력하거나 사진을 첨부해 주세요'; P5='미디어 추가'; P6='사진'; P7='동영상'; P8='음성'; P9='게시글에 추가'; P10='최대 9개 파일'; P11='제거'; P12='눌러서 녹음'; P13='눌러서 종료'; P14='취소'; P15='조금만 더 길게 녹음해 주세요'; P16='녹음에 실패했어요'; P17='음성을 추가하려면 마이크 접근 권한이 필요해요'; P18='게시'; P19='게시 중…'; P20='게시 완료'; P21='게시하지 못했어요. 다시 시도해 주세요'; P22='업로드 중 {current}/{total}…'; P23='이 게시글을 버릴까요?'; P24='작성한 내용은 사라져요.'; P25='버리기'; P26='계속 작성'; D1='게시글'; D2='좋아요'; D3='첫 좋아요를 남겨보세요'; D4='동영상 재생'; D5='동영상을 불러오지 못했어요'; D6='재생'; D7='일시정지'; FB='게시' }
  'my'      = @{ F1='မပို့ရသေးပါ'; F2='မိသားစုအတွက် ပထမဆုံး အပ်ဒိတ်တစ်ခု တင်လိုက်ပါ။'; F3='နောက်ထပ် မဆွဲနိုင်ပါ'; F4='ဤအပ်ဒိတ်ကို ဖျက်မလား?'; F5='ဖျက်ပြီးနောက် မိသားစုဝင်များအားလုံး မမြင်တွေ့နိုင်တော့ပါ။'; F6='ဖျက်မည်'; F7='အပ်ဒိတ် ဖျက်ပြီးပါပြီ'; F8='ကြိုက်တယ်'; F9='ကြိုက်ပြီးပါပြီ'; F10='{count, plural, =0{ကြိုက်တယ် 0 ခု} other{ကြိုက်တယ် {count} ခု}}'; F11='နောက်ထပ် {count} ယောက်'; F12='မှတ်ချက်မရှိသေးပါ'; F13='မှတ်ချက် လုပ်ဆောင်ချက် မကြာမီ ထပ်ထည့်မည်'; P1='အပ်ဒိတ်အသစ်'; P2='ဘာဖြစ်နေလဲ?'; P3='ဓာတ်ပုံတစ်ခုပဲ ဖြစ်ဖြစ်၊ စိတ်ခံစားချက်တစ်ခုပဲ ဖြစ်ဖြစ် မိသားစုနဲ့ ဝေမျှလိုက်ပါ။'; P4='စာတစ်ခုခု ရေးပါ သို့မဟုတ် ဓာတ်ပုံတစ်ခု ထည့်ပါ'; P5='မီဒီယာ ထည့်မည်'; P6='ဓာတ်ပုံ'; P7='ဗီဒီယို'; P8='အသံ'; P9='ဤအပ်ဒိတ်ထဲ ထည့်မည်'; P10='ဖိုင် 9 ခုအထိ'; P11='ဖယ်ရှားမည်'; P12='နှိပ်ပြီး အသံဖမ်းပါ'; P13='နှိပ်ပြီး ရပ်ပါ'; P14='မလုပ်တော့ပါ'; P15='နည်းနည်းပို၍ ဖမ်းပါ'; P16='အသံဖမ်းခြင်း မအောင်မြင်ပါ'; P17='အသံဖမ်းရန် မိုက်ကရိုဖုန်းခွင့်ပြုချက် လိုအပ်ပါသည်'; P18='တင်မည်'; P19='တင်နေသည်…'; P20='တင်ပြီးပါပြီ'; P21='တင်မရပါ။ ထပ်ကြိုးစားပါ'; P22='အပ်လုဒ် လုပ်နေသည် {current}/{total}…'; P23='ဤအပ်ဒိတ်ကို ဖယ်ထုတ်မလား?'; P24='ပြင်ဆင်ထားသည်များ ဆုံးရှုံးပါမည်။'; P25='ဖယ်ထုတ်မည်'; P26='ဆက်ပြင်ဆင်မည်'; D1='အပ်ဒိတ်'; D2='ကြိုက်သူများ'; D3='ပထမဆုံး ကြိုက်တာက သင်ဖြစ်ပါစေ'; D4='ဗီဒီယို ဖွင့်မည်'; D5='ဗီဒီယို မဆွဲနိုင်ပါ'; D6='ဖွင့်မည်'; D7='ခဏရပ်မည်'; FB='တင်မည်' }
}

# Mapping F1..F12 / P1..P26 / D1..D7 / FB → final ARB key name.
$mapping = @{
  F1='familyFeedEmptyTitle'; F2='familyFeedEmptyDesc'; F3='familyFeedLoadMoreError';
  F4='familyFeedDeleteTitle'; F5='familyFeedDeleteBody'; F6='familyFeedDeleteConfirm';
  F7='familyFeedDeleted'; F8='familyFeedLikeTooltip'; F9='familyFeedUnlikeTooltip';
  F10='familyFeedLikeCount'; F11='familyFeedMoreLikers'; F12='familyFeedNoCommentsYet';
  F13='familyFeedCommentsComingSoon';
  P1='publishMomentTitle'; P2='publishMomentContentLabel'; P3='publishMomentContentHint';
  P4='publishMomentContentRequired'; P5='publishMomentAddMedia';
  P6='publishMomentMediaTypeImage'; P7='publishMomentMediaTypeVideo';
  P8='publishMomentMediaTypeAudio'; P9='publishMomentAddMediaSheet';
  P10='publishMomentMaxMedia'; P11='publishMomentRemoveMedia';
  P12='publishMomentRecordingHint'; P13='publishMomentRecordingStop';
  P14='publishMomentRecordingCancel'; P15='publishMomentRecordingTooShort';
  P16='publishMomentRecordingFailed'; P17='publishMomentRecordingPermissionBody';
  P18='publishMomentPublish'; P19='publishMomentPublishing'; P20='publishMomentSuccess';
  P21='publishMomentFailed'; P22='publishMomentUploading';
  P23='publishMomentDiscardTitle'; P24='publishMomentDiscardBody';
  P25='publishMomentDiscardConfirm'; P26='publishMomentDiscardCancel';
  D1='momentDetailTitle'; D2='momentDetailWhoLikedTitle';
  D3='momentDetailNoLikes'; D4='momentDetailPlayVideo';
  D5='momentDetailVideoLoadFailed'; D6='momentDetailAudioPlay';
  D7='momentDetailAudioPause'; FB='familyFeedPublishButton'
}

function Escape-JsonValue([string]$s) {
  if ($null -eq $s) { return '' }
  $t = $s -replace '\\','\\\\'   # escape backslashes first
  $t = $t -replace '"','\\"'     # escape double quotes
  return $t
}

foreach ($locale in $block.Keys) {
  $path = "$arbDir/app_$locale.arb"
  $values = $block[$locale]
  $lines = @()
  foreach ($alias in $mapping.Keys) {
    if (-not $values.ContainsKey($alias)) {
      Write-Warning "$locale : missing short key '$alias'"
      continue
    }
    $finalKey = $mapping[$alias]
    $val = Escape-JsonValue $values[$alias]
    $lines += "  `"$finalKey`": `"$val`","
  }
  $pluralMeta = "  `"@familyFeedLikeCount`": {`n" +
                "    `"placeholders`": {`n" +
                "      `"count`": {`n" +
                "        `"type`": `"int`"`n" +
                "      }`n" +
                "    }`n" +
                "  },"
  $inj = "`n" + ($lines -join "`n") + "`n" + $pluralMeta
  $content = Get-Content $path -Raw
  $anchor = '  "familyFeedComingSoonDesc":'
  $idx = $content.IndexOf($anchor)
  if ($idx -lt 0) { Write-Warning "Anchor missing in $locale"; continue }
  $lineEnd = $content.IndexOf("`n", $idx)
  if ($lineEnd -lt 0) { $lineEnd = $content.Length }
  $insertAt = $lineEnd + 1
  $new = $content.Substring(0,$insertAt) + $inj + $content.Substring($insertAt)
  Set-Content -LiteralPath $path -Value $new -Encoding utf8 -NoNewline
  Write-Host "$locale : wrote $((Get-Item $path).Length) bytes"
}

Write-Host "Done."
