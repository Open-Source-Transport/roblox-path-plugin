export type Button = {
    Text: string?,
    Icon: string?,
    Tooltip: string?,
    Type: "Button",
    OnClick: () -> nil
};

export type ToggleButton = {
    Text: string?,
    Icon: string?,
    Tooltip: string?,
    Type: "ToggleButton",
    Activate: () -> nil,
    Deactivate: () -> nil
};

export type Text = {
    Type: "Text",
    Text: string,
    Tooltip: string?
}

export type Property<T> = {
    Key: string,
    DefaultValue: T,
    EmptyText: string?,
    SelectingText: string?,
    Unit: string?,
    Minimum: number?,
    Maximum: number?,
    Tooltip: string?,
    FormatString: string?,
    Type: "Boolean" | "Number" | "Slider" | "Instance",
    OnChange: (value: T) -> nil
};

export type InstanceTree = {
    Header: string,
    InstanceType: "Model" | "BasePart"?,
    Source: Instance,
    Recursive: boolean?,
    Type: "InstanceTree",
    OnChange: (value: Instance) -> nil,
};

export type Checklist = {
    Header: string,
    DefaultValues: boolean,
    Tooltip: string?,
    Options: {string} | {get: () -> {string}},
    Update: {get: () -> boolean, set: (value: boolean) -> nil},
    Type: "Checklist",
    OnChange: (value: {string}) -> nil
};

export type Element = Button | ToggleButton | Text | Property<boolean | number | Instance> | InstanceTree | Checklist;

export type SectionLayout = {
    Name: string,
    Contents: {[number]: Element}
};

return nil;