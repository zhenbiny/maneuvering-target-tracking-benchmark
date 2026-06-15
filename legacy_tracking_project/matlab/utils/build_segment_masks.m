function masks = build_segment_masks(time)
%BUILD_SEGMENT_MASKS Logical masks for maneuver and non-maneuver windows.

masks = struct();
masks.non_maneuver = (time < 400) ...
    | ((time >= 600) & (time < 610)) ...
    | (time >= 660);
masks.maneuver = ((time >= 400) & (time < 600)) ...
    | ((time >= 610) & (time < 660));
end
